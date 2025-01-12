#![allow(clippy::manual_c_str_literals)]
mod bindings;

use blake3::Hasher;
use rb_sys::{
    rb_cObject, rb_const_get, rb_define_class_under, rb_intern, rb_ivar_set, rb_require, size_t,
};
use std::ffi::{c_int, c_uchar, c_void};
use std::mem::MaybeUninit;
use std::os::raw::c_char;

use bindings::{rb_digest_make_metadata, RbDigestMetadataT, RUBY_DIGEST_API_VERSION};

#[repr(C)]
#[derive(Debug, Default)]
struct Blake3 {
    hasher: Hasher,
}

impl Blake3 {
    const BLOCK_LEN: usize = 64;
    const DIGEST_LEN: usize = 32;

    fn digest_metadata() -> &'static RbDigestMetadataT {
        static DIGEST_METADATA: RbDigestMetadataT = RbDigestMetadataT {
            api_version: RUBY_DIGEST_API_VERSION,
            digest_len: Blake3::DIGEST_LEN as _,
            block_len: Blake3::BLOCK_LEN as _,
            ctx_size: std::mem::size_of::<Blake3>() as _,
            init_func: Blake3::init_in_place,
            update_func: Blake3::update,
            finish_func: Blake3::finish,
        };
        &DIGEST_METADATA
    }

    // Initialize the context, which has already been allocated by Ruby.
    extern "C" fn init_in_place(ctx: *mut c_void) -> c_int {
        let ctx = ctx as *mut MaybeUninit<Blake3>;
        let ctx = unsafe { &mut *ctx };
        ctx.write(Blake3::default());
        true as _
    }

    // Update the context with the given data.
    extern "C" fn update(ctx: *mut c_void, data: *mut c_uchar, len: size_t) {
        let ctx = ctx as *mut MaybeUninit<Blake3>;
        let ctx = unsafe { &mut *ctx };
        let ctx = unsafe { ctx.assume_init_mut() };
        let slice = unsafe { std::slice::from_raw_parts(data, len as _) };

        ctx.hasher.update(slice);
    }

    // Finalize the context and write the digest to the given pointer. The
    // memory for the digest is managed by Ruby, so we don't need to free it.
    extern "C" fn finish(ctx: *mut c_void, digest: *mut c_uchar) -> c_int {
        let ctx = ctx as *mut MaybeUninit<Blake3>;
        let ctx = unsafe { &mut *ctx };
        let ctx = unsafe { ctx.assume_init_mut() };
        let outbuf = unsafe { std::slice::from_raw_parts_mut(digest, Self::DIGEST_LEN) };
        ctx.hasher.finalize_xof().fill(outbuf);
        true as _
    }
}

/// # Safety
/// This function is called by Ruby, so it must be safe.
#[no_mangle]
pub unsafe extern "C" fn Init_blake3_ext() {
    rb_require("digest\0".as_ptr() as *const c_char);
    let digest_module = rb_const_get(rb_cObject, rb_intern("Digest\0".as_ptr() as *const c_char));
    let digest_base = rb_const_get(digest_module, rb_intern("Base\0".as_ptr() as *const c_char));
    let klass = rb_define_class_under(
        digest_module,
        "Blake3\0".as_ptr() as *const c_char,
        digest_base,
    );
    let meta = rb_digest_make_metadata(Blake3::digest_metadata());
    let metadata_id = rb_intern("metadata\0".as_ptr() as *const c_char);
    rb_ivar_set(klass, metadata_id, meta);
}

#[cfg(test)]
mod tests {
    use rb_sys::{
        rb_cObject, rb_const_get, rb_enc_set_index, rb_funcallv_public, rb_intern, rb_str_new,
        rb_utf8_encindex, RSTRING_LEN, RSTRING_PTR,
    };
    use rb_sys_test_helpers::{protect, ruby_test};

    use crate::Init_blake3_ext;

    #[ruby_test]
    fn fuzz_parity_binary() {
        setup();

        for _ in 0..1024 {
            let input_data = gen_random_bytes(4096);
            let expected = compute_rust_digest(input_data.as_slice());
            let actual = compute_ruby_digest(input_data.as_slice(), rb_utf8_encindex);

            assert_eq!(expected, actual);
        }
    }

    #[ruby_test]
    fn fuzz_parity_utf8() {
        setup();

        for _ in 0..1024 {
            let input_data = gen_random_string(512);
            let expected = compute_rust_digest(&input_data);
            let actual = compute_ruby_digest(&input_data, rb_utf8_encindex);

            assert_eq!(expected, actual);
        }
    }

    fn setup() {
        static INIT: std::sync::Once = std::sync::Once::new();
        INIT.call_once(|| {
            protect(|| unsafe { Init_blake3_ext() })
                .expect("Failed to initialize Blake3 extension");
        });
    }

    fn gen_random_bytes(max_len: usize) -> Vec<u8> {
        let size = rand::random::<usize>() % max_len;
        (0..size).map(|_| rand::random::<u8>()).collect()
    }

    fn gen_random_string(max_len: usize) -> String {
        let size = rand::random::<usize>() % max_len;
        (0..size)
            .map(|_| rand::random::<char>())
            .collect::<String>()
    }

    fn compute_rust_digest<T: AsRef<[u8]>>(input: T) -> String {
        let mut hasher = blake3::Hasher::new();
        hasher.update(input.as_ref());
        let mut result = [0u8; 32];
        hasher.finalize_xof().fill(&mut result);
        hex::encode(result)
    }

    fn compute_ruby_digest<T: AsRef<[u8]>>(
        input: T,
        encoding: unsafe extern "C" fn() -> i32,
    ) -> String {
        let input = input.as_ref();
        let ruby_digest = protect(|| unsafe {
            Init_blake3_ext();
            let klass = rb_const_get(rb_cObject, rb_intern("Digest\0".as_ptr() as _));
            let klass = rb_const_get(klass, rb_intern("Blake3\0".as_ptr() as _));
            let string = rb_str_new(input.as_ptr() as _, input.len() as _);
            rb_enc_set_index(string, encoding());
            let mut args = [string];
            rb_funcallv_public(
                klass,
                rb_intern("hexdigest\0".as_ptr() as _),
                args.len() as _,
                args.as_mut_ptr(),
            )
        })
        .unwrap();

        let rstring_ptr = unsafe { RSTRING_PTR(ruby_digest) };
        let rstring_len = unsafe { RSTRING_LEN(ruby_digest) };

        let bytes =
            unsafe { std::slice::from_raw_parts(rstring_ptr as *const u8, rstring_len as _) };
        std::str::from_utf8(bytes).unwrap().to_string()
    }
}

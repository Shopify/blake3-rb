mod bindings;

use blake3::Hasher;
use rb_sys::{
    rb_cObject, rb_const_get, rb_define_class_under, rb_intern, rb_ivar_set, rb_require, size_t,
};
use std::ffi::{c_int, c_uchar, c_void};
use std::os::raw::c_char;

use bindings::{rb_digest_make_metadata, RbDigestMetadataT, RUBY_DIGEST_API_VERSION};

const BLOCK_LEN: usize = 64;
const DIGEST_LEN: usize = 32;

#[repr(C)]
#[derive(Debug)]
struct Blake3Ctx {
    inner: Option<Hasher>,
}

static DIGEST_METADATA: RbDigestMetadataT = RbDigestMetadataT {
    api_version: RUBY_DIGEST_API_VERSION,
    digest_len: DIGEST_LEN as _,
    block_len: BLOCK_LEN as _,
    ctx_size: std::mem::size_of::<Blake3Ctx>() as _,
    init_func: blake3_init,
    update_func: blake3_update,
    finish_func: blake3_finish,
};

// Initialize the context, which has already been allocated by Ruby.
extern "C" fn blake3_init(ctx: *mut c_void) -> c_int {
    let ctx = ctx as *mut Blake3Ctx;
    let ctx = unsafe { &mut *ctx };
    ctx.inner = Some(Hasher::new());
    1
}

// Update the context with the given data.
extern "C" fn blake3_update(ctx: *mut c_void, data: *mut c_uchar, len: size_t) {
    let ctx = ctx as *mut Blake3Ctx;
    let ctx = unsafe { &mut *ctx };
    if let Some(inner) = ctx.inner.as_mut() {
        let slice = unsafe { std::slice::from_raw_parts(data, len as _) };
        inner.update(slice);
    }
}

// Finalize the context and write the digest to the given pointer.
extern "C" fn blake3_finish(ctx: *mut c_void, digest: *mut c_uchar) -> c_int {
    let ctx = ctx as *mut Blake3Ctx;
    let ctx = unsafe { &mut *ctx };
    if let Some(inner) = ctx.inner.as_mut() {
        let slice = unsafe { std::slice::from_raw_parts_mut(digest, DIGEST_LEN) };
        inner.finalize_xof().fill(slice);
        1
    } else {
        0
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
    let meta = rb_digest_make_metadata(&DIGEST_METADATA);
    let metadata_id = rb_intern("metadata\0".as_ptr() as *const c_char);
    rb_ivar_set(klass, metadata_id, meta);
}

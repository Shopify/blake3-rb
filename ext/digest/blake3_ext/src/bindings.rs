use rb_sys::{size_t, VALUE};
use std::ffi::{c_int, c_uchar, c_void};

pub const RUBY_DIGEST_API_VERSION: c_int = 3;

pub type RbDigestHashInitFuncT = unsafe extern "C" fn(*mut c_void) -> c_int;
pub type RbDigestHashUpdateFuncT = unsafe extern "C" fn(*mut c_void, *mut c_uchar, size_t);
pub type RbDigestHashFinishFuncT = unsafe extern "C" fn(*mut c_void, *mut c_uchar) -> c_int;

#[derive(Debug)]
#[repr(C)]
pub struct RbDigestMetadataT {
    pub api_version: c_int,
    pub digest_len: size_t,
    pub block_len: size_t,
    pub ctx_size: size_t,
    pub init_func: RbDigestHashInitFuncT,
    pub update_func: RbDigestHashUpdateFuncT,
    pub finish_func: RbDigestHashFinishFuncT,
}

#[cfg(ruby_gt_3_3)]
pub unsafe fn rb_digest_make_metadata(meta: &'static RbDigestMetadataT) -> VALUE {
    static mut WRAPPER: Option<unsafe extern "C" fn(&'static RbDigestMetadataT) -> VALUE> = None;

    unsafe fn load_wrapper() {
        use rb_sys::rb_ext_resolve_symbol;
        use std::ffi::c_char;
        use std::sync::Once;

        static INIT: Once = Once::new();

        INIT.call_once(|| {
            let lib_name = "digest.so\0".as_ptr() as *const c_char;
            let symbol_name = "rb_digest_wrap_metadata\0".as_ptr() as *const c_char;
            let symbol_ptr = rb_ext_resolve_symbol(lib_name, symbol_name);

            if !symbol_ptr.is_null() {
                WRAPPER = Some(std::mem::transmute(symbol_ptr));
            } else {
                panic!("Failed to resolve rb_digest_wrap_metadata");
            }
        });
    }

    load_wrapper();
    if let Some(wrapper) = WRAPPER {
        return wrapper(meta);
    }
    panic!("Failed to resolve rb_digest_wrap_metadata");
}

#[cfg(not(ruby_gt_3_3))]
pub unsafe fn rb_digest_make_metadata(meta: &'static RbDigestMetadataT) -> VALUE {
    use rb_sys::{rb_data_object_wrap, rb_obj_freeze};
    let data = rb_data_object_wrap(
        0 as VALUE,
        meta as *const RbDigestMetadataT as *mut c_void,
        None,
        None,
    );
    rb_obj_freeze(data)
}

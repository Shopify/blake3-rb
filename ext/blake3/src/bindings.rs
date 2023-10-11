use std::ffi::{c_int, c_uchar, c_void};

use rb_sys::{rb_data_object_wrap, rb_obj_freeze, size_t, VALUE};

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

pub unsafe fn rb_digest_make_metadata(meta: &'static RbDigestMetadataT) -> VALUE {
    let data = rb_data_object_wrap(
        0 as VALUE,
        meta as *const RbDigestMetadataT as *mut c_void,
        None,
        None,
    );
    rb_obj_freeze(data)
}

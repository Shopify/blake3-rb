use std::cell::{Ref, RefCell, RefMut};

use base64::{prelude::BASE64_STANDARD, Engine};
use magnus::{
    class::object,
    encoding::RbEncoding,
    exception::arg_error,
    function, method,
    typed_data::Obj,
    value::{InnerValue, Lazy, ReprValue},
    Error, Integer, Module, Object, RString, Ruby, TryConvert, Value,
};

use crate::{ERROR_CLASS, ROOT_MODULE};

#[magnus::wrap(class = "Blake3::Digest", free_immediately)]
pub struct Digest {
    inner: RefCell<blake3_impl::Hasher>,
}

impl Digest {
    pub fn new() -> Self {
        Self {
            inner: RefCell::new(blake3_impl::Hasher::new()),
        }
    }

    pub fn from_file(filename: RString) -> Result<Self, Error> {
        let mut hasher = blake3_impl::Hasher::new();
        let mut file = std::fs::File::open(unsafe { filename.as_str()? })
            .map_err(|e| Error::new(arg_error(), format!("Error opening file: {}", e)))?;

        std::io::copy(&mut file, &mut hasher).map_err(|e| {
            Error::new(
                ERROR_CLASS.get_inner_with(&Ruby::get().expect("Ruby interpreter not initialized")),
                format!("Error reading file: {}", e),
            )
        })?;

        Ok(Self {
            inner: RefCell::new(hasher),
        })
    }

    pub fn cloned(&self) -> Result<Self, Error> {
        let hasher = self.inner()?.clone();

        Ok(Self {
            inner: RefCell::new(hasher),
        })
    }

    pub fn reset(rb_self: Obj<Self>) -> Result<Obj<Self>, Error> {
        rb_self.inner_mut()?.reset();

        Ok(rb_self)
    }

    pub fn update(rb_self: Obj<Self>, input: RString) -> Result<Obj<Self>, Error> {
        let mut hasher = rb_self.inner_mut()?;
        hasher.update(unsafe { input.as_slice() });

        Ok(rb_self)
    }

    pub fn digest(&self) -> Result<RString, Error> {
        let hasher = self.inner()?;
        let hash = hasher.finalize();
        let outstring = RString::enc_new(hash.as_bytes(), RbEncoding::ascii8bit());

        Ok(outstring)
    }

    pub fn digest_and_reset(&self) -> Result<RString, Error> {
        let ret = self.digest()?;
        self.inner_mut()?.reset();

        Ok(ret)
    }

    pub fn hexdigest(&self) -> Result<RString, Error> {
        static EMPTY_SLICE: [u8; 64] = [b' '; 64];

        let hasher = self.inner()?;
        let hash = hasher.finalize();
        let outstring = RString::enc_new(EMPTY_SLICE, RbEncoding::usascii());

        // SAFETY: We are the only ones with access to this string's internal
        // buffer, and we know it's the proper length for the hash, so we save
        // an allocation by using it directly.
        let mut_slice = unsafe { rstring_mut_slice(outstring) };

        hex::encode_to_slice(hash.as_bytes(), mut_slice).map_err(|e| {
            Error::new(
                ERROR_CLASS.get_inner_with(&Ruby::get().expect("Ruby interpreter not initialized")),
                format!("Error encoding hash to hex: {}", e),
            )
        })?;

        Ok(outstring)
    }

    fn hexdigest_and_reset(&self) -> Result<RString, Error> {
        let ret = self.hexdigest()?;
        self.inner_mut()?.reset();

        Ok(ret)
    }

    pub fn base64digest(&self) -> Result<RString, Error> {
        static EMPTY_SLICE: [u8; 44] = [b' '; 44];

        let hasher = self.inner()?;
        let hash = hasher.finalize();
        let outstring = RString::enc_new(EMPTY_SLICE, RbEncoding::usascii());

        // SAFETY: We are the only ones with access to this string's internal
        // buffer, and we know it's the proper length for the hash, so we save
        // an allocation by using it directly.
        let mut_slice = unsafe { rstring_mut_slice(outstring) };

        BASE64_STANDARD
            .encode_slice(hash.as_bytes(), mut_slice)
            .map_err(|e| {
                Error::new(
                    ERROR_CLASS
                        .get_inner_with(&Ruby::get().expect("Ruby interpreter not initialized")),
                    format!("Error encoding hash to base64: {}", e),
                )
            })?;

        Ok(outstring)
    }

    pub fn base64digest_and_reset(&self) -> Result<RString, Error> {
        let ret = self.base64digest()?;
        self.inner_mut()?.reset();

        Ok(ret)
    }

    pub fn digest_length(&self) -> Integer {
        static DIGEST_LEN: Lazy<Integer> = Lazy::new(|ruby| ruby.integer_from_u64(32));
        DIGEST_LEN.get_inner_with(&Ruby::get().expect("Ruby interpreter not initialized"))
    }

    pub fn block_length(&self) -> Integer {
        static BLOCK_LEN: Lazy<Integer> = Lazy::new(|ruby| ruby.integer_from_u64(64));
        BLOCK_LEN.get_inner_with(&Ruby::get().expect("Ruby interpreter not initialized"))
    }

    pub fn inspect(&self) -> Result<RString, Error> {
        let outstring = RString::enc_new("#<Blake3::Digest: ", RbEncoding::usascii());
        outstring.buf_append(self.hexdigest()?)?;
        outstring.cat(">");

        Ok(outstring)
    }

    fn inner(&self) -> Result<Ref<'_, blake3_impl::Hasher>, Error> {
        let ruby = Ruby::get().expect("Ruby interpreter not initialized");
        self.inner
            .try_borrow()
            .map_err(|e| Error::new(ERROR_CLASS.get_inner_with(&ruby), format!("{}", e)))
    }

    fn is_equal(rb_self: Obj<Self>, other: Value) -> Result<bool, Error> {
        if let Ok(other_digest) = Obj::<Self>::try_convert(other) {
            Ok(other_digest.inner()?.finalize() == rb_self.inner()?.finalize())
        } else if let Ok(other_string) = RString::try_convert(other) {
            let self_hex = rb_self.hexdigest()?;
            Ok(self_hex.eql(other_string)?)
        } else {
            Ok(false)
        }
    }

    fn inner_mut(&self) -> Result<RefMut<'_, blake3_impl::Hasher>, Error> {
        let ruby = Ruby::get().expect("Ruby interpreter not initialized");
        self.inner
            .try_borrow_mut()
            .map_err(|e| Error::new(ERROR_CLASS.get_inner_with(&ruby), format!("{}", e)))
    }
}

unsafe fn rstring_mut_slice<'a>(string: RString) -> &'a mut [u8] {
    let slice = string.as_slice();
    let ptr = slice.as_ptr() as *mut u8;
    let len = slice.len();
    std::slice::from_raw_parts_mut(ptr, len)
}

pub(crate) fn init() -> Result<(), Error> {
    let ruby = Ruby::get().expect("Ruby interpreter not initialized");

    let klass = ROOT_MODULE
        .get_inner_with(&ruby)
        .define_class("Digest", object())?;

    klass.define_singleton_method("new", function!(Digest::new, 0))?;
    klass.define_singleton_method("file", function!(Digest::from_file, 1))?;

    klass.define_method("new", method!(Digest::cloned, 0))?;
    klass.define_method("inspect", method!(Digest::inspect, 0))?;
    klass.define_method("update", method!(Digest::update, 1))?;
    klass.define_method("reset", method!(Digest::reset, 0))?;
    klass.define_method("digest_length", method!(Digest::digest_length, 0))?;
    klass.define_method("block_length", method!(Digest::block_length, 0))?;
    klass.define_method("size", method!(Digest::digest_length, 0))?;
    klass.define_method("<<", method!(Digest::update, 1))?;
    klass.define_method("digest", method!(Digest::digest, 0))?;
    klass.define_method("digest!", method!(Digest::digest_and_reset, 0))?;
    klass.define_method("hexdigest", method!(Digest::hexdigest, 0))?;
    klass.define_method("to_s", method!(Digest::hexdigest, 0))?;
    klass.define_method("hexdigest!", method!(Digest::hexdigest_and_reset, 0))?;
    klass.define_method("base64digest", method!(Digest::base64digest, 0))?;
    klass.define_method("base64digest!", method!(Digest::base64digest_and_reset, 0))?;
    klass.define_method("==", method!(Digest::is_equal, 1))?;

    Ok(())
}

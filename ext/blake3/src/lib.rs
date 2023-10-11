mod digest;

use magnus::{
    exception::standard_error,
    value::{InnerValue, Lazy},
    Error, ExceptionClass, Module, RModule,
};

pub(crate) static ROOT_MODULE: Lazy<RModule> =
    Lazy::new(|ruby| ruby.define_module("Blake3").unwrap());

pub(crate) static ERROR_CLASS: Lazy<ExceptionClass> = Lazy::new(|ruby| {
    ROOT_MODULE
        .get_inner_with(ruby)
        .define_error("Error", standard_error())
        .unwrap()
});

#[magnus::init]
pub fn init() -> Result<(), Error> {
    digest::init()?;
    Ok(())
}

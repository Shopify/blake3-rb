mod bindings;
mod digest;

#[no_mangle]
pub extern "C" fn Init_blake3() {
    // # Safety
    // This function is called from Ruby, so it must be safe.
    unsafe { digest::init() };
}

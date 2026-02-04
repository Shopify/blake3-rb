/*
 * BLAKE3 Ruby extension using Ruby's Digest framework
 */
#include <ruby.h>
#include <ruby/digest.h>
#include "blake3/blake3.h"

#define BLAKE3_DIGEST_LENGTH 32
#define BLAKE3_BLOCK_LENGTH 64

/*
 * Context structure that wraps the blake3_hasher.
 * This is allocated by Ruby and initialized in place.
 */
typedef struct {
    blake3_hasher hasher;
} blake3_ctx_t;

/*
 * Initialize the hasher context.
 * Called by Ruby's Digest framework when creating a new digest object.
 */
static int
blake3_init(void *ctx)
{
    blake3_ctx_t *context = (blake3_ctx_t *)ctx;
    blake3_hasher_init(&context->hasher);
    return 1;
}

/*
 * Update the hasher with input data.
 * Called by Ruby's Digest framework when data is added to the digest.
 */
static void
blake3_update(void *ctx, unsigned char *data, size_t len)
{
    blake3_ctx_t *context = (blake3_ctx_t *)ctx;
    blake3_hasher_update(&context->hasher, data, len);
}

/*
 * Finalize the hash and output the digest.
 * Called by Ruby's Digest framework to produce the final hash value.
 */
static int
blake3_finish(void *ctx, unsigned char *digest)
{
    blake3_ctx_t *context = (blake3_ctx_t *)ctx;
    blake3_hasher_finalize(&context->hasher, digest, BLAKE3_DIGEST_LENGTH);
    return 1;
}

/*
 * Metadata structure for Ruby's Digest framework.
 * This tells Ruby how to use our hash functions.
 */
static const rb_digest_metadata_t blake3_metadata = {
    RUBY_DIGEST_API_VERSION,
    BLAKE3_DIGEST_LENGTH,
    BLAKE3_BLOCK_LENGTH,
    sizeof(blake3_ctx_t),
    (rb_digest_hash_init_func_t)blake3_init,
    (rb_digest_hash_update_func_t)blake3_update,
    (rb_digest_hash_finish_func_t)blake3_finish,
};

/*
 * Extension initialization function.
 * Called by Ruby when the extension is loaded.
 */
void
Init_blake3_ext(void)
{
    VALUE mDigest, cDigest_Base, cDigest_Blake3;

    /* Require digest module */
    rb_require("digest");

    /* Get Digest module and Digest::Base class */
    mDigest = rb_const_get(rb_cObject, rb_intern("Digest"));
    cDigest_Base = rb_const_get(mDigest, rb_intern("Base"));

    /* Define Digest::Blake3 class as subclass of Digest::Base */
    cDigest_Blake3 = rb_define_class_under(mDigest, "Blake3", cDigest_Base);

    /* Set the metadata instance variable that Ruby's Digest framework expects */
    rb_ivar_set(cDigest_Blake3, rb_id_metadata(),
                rb_digest_make_metadata(&blake3_metadata));
}

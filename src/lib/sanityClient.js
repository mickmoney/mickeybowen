import {createClient} from '@sanity/client'
import {createImageUrlBuilder} from '@sanity/image-url'

export const sanityClient = createClient({
  projectId: import.meta.env.SANITY_PROJECT_ID,
  dataset: import.meta.env.SANITY_DATASET || 'production',
  apiVersion: '2024-01-01',
  // Build reads published content only — no token needed.
  // If you later want draft previews, add a read token here
  // and gate it behind an env var, never commit it.
  useCdn: true,
})

const builder = createImageUrlBuilder(sanityClient)

export function urlFor(source) {
  return builder.image(source)
}

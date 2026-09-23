/**
 * Fetches the single homePage document plus the latest N posts for the
 * blog teaser section (N comes from homePage.blogPostCount).
 */
export const HOME_PAGE_QUERY = `
{
  "page": *[_type == "homePage"][0]{
    heroPreHeadline,
    heroHeadline,
    heroSubtext,
    heroPrimaryCta,
    heroSecondaryCta,
    heroReassurance,

    logoCloudHeading,
    logos,

    testimonialsTop,

    problemEyebrow,
    problemHeading,
    problemBody,
    painPoints,

    solutionHeading,
    solutionBody,
    solutionCta,

    processHeading,
    processSteps,

    pricingEyebrow,
    pricingHeading,
    pricingBody,
    pricingPlans,

    aboutEyebrow,
    aboutHeading,
    aboutPhoto,
    aboutBullets,

    workHeading,
    workItems,

    faqItems,

    finalTestimonial,

    ctaHeading,
    ctaSubtext,
    ctaButton,

    socialProofRating,
    socialProofText,

    blogHeading,
    blogPostCount,

    seoTitle,
    seoDescription
  },
  "posts": *[_type == "post"] | order(publishedAt desc)[0...$postCount]{
    title,
    slug,
    excerpt,
    mainImage,
    publishedAt
  }
}
`

export const SITE_SETTINGS_QUERY = `
*[_type == "siteSettings"][0]{
  siteName,
  navLinks,
  navCta,
  navAvatar,
  footerText,
  socialLinks,
  defaultSeoTitle,
  defaultSeoDescription,
  defaultOgImage
}
`

export const ALL_POST_SLUGS_QUERY = `
*[_type == "post" && defined(slug.current)][].slug.current
`

export const POST_BY_SLUG_QUERY = `
*[_type == "post" && slug.current == $slug][0]{
  title,
  slug,
  excerpt,
  mainImage,
  publishedAt,
  author,
  tags,
  body
}
`

export const BLOG_LIST_QUERY = `
*[_type == "post"] | order(publishedAt desc){
  title,
  slug,
  excerpt,
  mainImage,
  publishedAt,
  author
}
`

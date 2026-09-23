#!/bin/bash
set -e
echo "Rewriting src/pages/blog/[slug].astro (removes embedded special characters)..."
mkdir -p src/pages/blog
cat > "src/pages/blog/[slug].astro" << 'SLUG_EOF'
---
import { sanityClient, urlFor } from '../../lib/sanityClient';
import { ALL_POST_SLUGS_QUERY, POST_BY_SLUG_QUERY, SITE_SETTINGS_QUERY } from '../../lib/queries';

export async function getStaticPaths() {
  const slugs = await sanityClient.fetch(ALL_POST_SLUGS_QUERY);
  return (slugs ?? []).map((slug) => ({ params: { slug } }));
}

const { slug } = Astro.params;
const post = await sanityClient.fetch(POST_BY_SLUG_QUERY, { slug });
const settings = await sanityClient.fetch(SITE_SETTINGS_QUERY);

const navLinks = settings?.navLinks?.length
  ? settings.navLinks
  : [
      { label: 'Work', anchor: '/#work' },
      { label: 'Process', anchor: '/#process' },
      { label: 'About', anchor: '/#about' },
      { label: 'Blog', anchor: '/blog' },
    ];
const navCta = settings?.navCta ?? {
  label: 'Chat with Mickey',
  url: 'https://calendly.com/mickeybowen/30min',
  openInNewTab: true,
};
const footerText = settings?.footerText ?? '\u00A9 2026 Mickey Bowen';

// Minimal Portable Text -> HTML renderer. Covers the block types and marks
// this blog actually uses (paragraphs, headings, quotes, lists, bold/italic/
// links, and inline images). Good enough for standard posts without pulling
// in a whole rendering library.
function renderBlock(block) {
  if (block._type === 'image') {
    const src = urlFor(block).width(900).url();
    return `<img src="${src}" alt="" loading="lazy" />`;
  }
  if (block._type !== 'block') return '';

  const text = (block.children ?? [])
    .map((child) => {
      let t = child.text ?? '';
      // Escape basic HTML first
      t = t.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
      (child.marks ?? []).forEach((mark) => {
        if (mark === 'strong') t = `<strong>${t}</strong>`;
        if (mark === 'em') t = `<em>${t}</em>`;
        if (mark === 'code') t = `<code>${t}</code>`;
        const link = (block.markDefs ?? []).find((d) => d._key === mark && d._type === 'link');
        if (link) t = `<a href="${link.href}" target="_blank" rel="noopener">${t}</a>`;
      });
      return t;
    })
    .join('');

  switch (block.style) {
    case 'h2': return `<h2>${text}</h2>`;
    case 'h3': return `<h3>${text}</h3>`;
    case 'blockquote': return `<blockquote>${text}</blockquote>`;
    default: return `<p>${text}</p>`;
  }
}

function renderBody(body) {
  if (!body?.length) return '';
  // Group consecutive bullet/number list items into <ul>/<ol>
  let html = '';
  let listBuffer = [];
  let listType = null;

  const flushList = () => {
    if (!listBuffer.length) return;
    const tag = listType === 'number' ? 'ol' : 'ul';
    html += `<${tag}>${listBuffer.map((b) => `<li>${b}</li>`).join('')}</${tag}>`;
    listBuffer = [];
    listType = null;
  };

  body.forEach((block) => {
    if (block._type === 'block' && block.listItem) {
      if (listType && listType !== block.listItem) flushList();
      listType = block.listItem;
      const inner = renderBlock({ ...block, style: 'normal' }).replace(/^<p>|<\/p>$/g, '');
      listBuffer.push(inner);
    } else {
      flushList();
      html += renderBlock(block);
    }
  });
  flushList();
  return html;
}

const bodyHtml = renderBody(post?.body);
const formattedDate = post?.publishedAt
  ? new Date(post.publishedAt).toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })
  : '';
---
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>{post?.title ?? 'Post'} | {settings?.siteName ?? 'Mickey Bowen'}</title>
  {post?.excerpt && <meta name="description" content={post.excerpt} />}
</head>
<body>
  <div class="nav-bar">
    <nav>
      <a href="/" class="logo">{settings?.siteName ?? 'Mickey Bowen'}</a>
      <div class="links">
        {navLinks.map((link) => (
          <a href={link.anchor}>{link.label}</a>
        ))}
      </div>
      <div class="nav-cta">
        <a
          href={navCta.url}
          target={navCta.openInNewTab ? '_blank' : undefined}
          rel={navCta.openInNewTab ? 'noopener' : undefined}
          class="btn btn-primary nav-btn"
        >
          {navCta.label}
        </a>
      </div>
    </nav>
  </div>

  <article class="wrap">
    <a href="/blog" class="back">&larr; Back to blog</a>
    <p class="meta">{formattedDate}{post?.author ? ` \u00B7 ${post.author}` : ''}</p>
    <h1>{post?.title}</h1>
    {post?.mainImage && (
      <img class="hero-img" src={urlFor(post.mainImage).width(1200).url()} alt={post.title} />
    )}
    <div class="prose" set:html={bodyHtml}></div>

    {post?.tags?.length > 0 && (
      <div class="tags">
        {post.tags.map((tag) => <span class="tag">{tag}</span>)}
      </div>
    )}
  </article>

  <footer>
    <span>{footerText}</span>
  </footer>
</body>
</html>

<style>
  :root {
    --ink: #0B1220;
    --ink-soft: #5B6472;
    --ink-faint: #94A3B8;
    --blue: #2A5BFF;
    --off-white: #FAF9F6;
    --line: #E7EAF0;
  }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
    color: var(--ink);
    background: #FFFFFF;
  }
  a { color: var(--blue); }
  .wrap { max-width: 720px; margin: 0 auto; padding: 0 24px; }

  .nav-bar { background: var(--off-white); border-bottom: 1px solid var(--line); }
  nav {
    max-width: 1080px; margin: 0 auto; padding: 16px 24px;
    display: flex; align-items: center; justify-content: space-between; gap: 24px;
  }
  .logo { font-weight: 700; font-size: 16px; color: var(--ink); text-decoration: none; }
  .links { display: flex; gap: 28px; font-size: 14px; color: var(--ink-soft); }
  .links a { color: inherit; text-decoration: none; }
  .links a:hover { color: var(--ink); }
  .btn { display: inline-block; padding: 10px 20px; border-radius: 999px; font-weight: 600; font-size: 14px; text-decoration: none; }
  .btn-primary { background: var(--blue); color: #fff; }

  article { padding: 48px 24px 100px; }
  .back { font-size: 13px; font-weight: 600; display: inline-block; margin-bottom: 24px; text-decoration: none; }
  .meta { color: var(--ink-faint); font-size: 13px; margin: 0 0 8px; }
  h1 { font-size: 34px; line-height: 1.2; margin: 0 0 24px; }
  .hero-img { width: 100%; border-radius: 12px; margin-bottom: 32px; display: block; }

  .prose { font-size: 17px; line-height: 1.7; color: var(--ink); }
  .prose p { margin: 0 0 20px; }
  .prose h2 {
    font-size: 24px; margin: 48px 0 14px; padding-top: 32px;
    border-top: 1px solid var(--line);
  }
  .prose h3 { font-size: 19px; margin: 28px 0 10px; }
  .prose blockquote {
    margin: 24px 0; padding: 4px 20px; border-left: 3px solid var(--blue);
    color: var(--ink-soft); font-style: italic;
  }
  .prose img { max-width: 100%; border-radius: 10px; margin: 24px 0; }
  .prose ul, .prose ol { margin: 0 0 20px; padding-left: 24px; }
  .prose li { margin-bottom: 8px; }
  .prose code { background: var(--off-white); padding: 2px 6px; border-radius: 4px; font-size: 15px; }

  .tags { margin-top: 40px; display: flex; gap: 8px; flex-wrap: wrap; }
  .tag {
    font-size: 12px; color: var(--ink-soft); background: var(--off-white);
    padding: 5px 12px; border-radius: 999px; border: 1px solid var(--line);
  }

  footer {
    padding: 28px 24px; border-top: 1px solid var(--line);
    color: var(--ink-faint); font-size: 13px; text-align: center;
  }
</style>
SLUG_EOF
echo "Done. Run: npm run dev"

import { Extension } from '@tiptap/core'
import { Plugin, PluginKey } from '@tiptap/pm/state'

function scrollToHeadingById(id: string) {
  const target = document.getElementById(id)
  if (!target) return
  // Prefer smooth scroll and center in view
  try {
    target.scrollIntoView({ behavior: 'smooth', block: 'center' })
  } catch {
    const y = target.getBoundingClientRect().top + window.scrollY - 80
    window.scrollTo({ top: y, behavior: 'smooth' })
  }
}

export const InternalLinkNavigation = Extension.create({
  name: 'internalLinkNavigation',

  addProseMirrorPlugins() {
    return [
      new Plugin({
        key: new PluginKey('internalLinkNavigation'),
        props: {
          handleClick: (_view, _pos, event) => {
            const el = event.target as HTMLElement | null
            const anchor = el?.closest?.('a') as HTMLAnchorElement | null
            const href = anchor?.getAttribute('href')?.trim() || ''
            if (!href || !href.startsWith('#')) return false
            event.preventDefault()
            const id = href.slice(1)
            if (!id) return true
            scrollToHeadingById(id)
            try {
              const encoded = encodeURIComponent(id)
              if (window.location.hash !== `#${encoded}`) {
                window.history.pushState(null, '', `#${encoded}`)
              }
            } catch {}
            return true
          },
        },
      }),
    ]
  },
})


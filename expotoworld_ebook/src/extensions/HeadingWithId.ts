import Heading from '@tiptap/extension-heading'
import { Plugin, PluginKey } from '@tiptap/pm/state'
import type { Attrs } from '@tiptap/pm/model'
import { nanoid } from 'nanoid'

const ID_PREFIX = 'h.'
const newHeadingId = () => `${ID_PREFIX}${nanoid(8)}`

export const HeadingWithId = Heading.extend({
  addOptions() {
    // Restrict to H1-H4 as requested
    return {
      ...this.parent?.(),
      levels: [1, 2, 3, 4],
    }
  },

  addAttributes() {
    // Merge parent attributes (including required `level`) and add our `id` attribute.
    const parent = (this.parent?.() as any) || {}
    return {
      ...parent,
      id: {
        default: null,
        parseHTML: (element: HTMLElement) => element.getAttribute('id'),
        renderHTML: (attributes: Record<string, any>) => (attributes.id ? { id: attributes.id } : {}),
      },
    }
  },

  addProseMirrorPlugins() {
    // Keep parent plugins if any
    const parentPlugins = (this.parent?.() as any) || []
    return [
      ...(Array.isArray(parentPlugins) ? parentPlugins : [parentPlugins]),
      new Plugin({
        key: new PluginKey('headingIds'),
        appendTransaction: (_trs, _oldState, newState) => {
          let tr = newState.tr
          let changed = false
          const used = new Set<string>()

          newState.doc.descendants((node, pos) => {
            if (node.type.name !== this.name) return
            const attrs: Attrs = { ...(node.attrs as any) }
            let id = (attrs as any).id as string | null

            if (id && used.has(id)) {
              id = null
            }

            if (!id) {
              id = newHeadingId()
              tr = tr.setNodeMarkup(pos, undefined, { ...attrs, id })
              changed = true
            }

            if (id) used.add(id)
          })

          return changed ? tr : null
        },
      }),
    ]
  },
})


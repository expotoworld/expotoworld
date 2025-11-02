import { Node, mergeAttributes } from '@tiptap/core'
import type { Editor } from '@tiptap/react'
import type { DictTerm } from './DictionaryTerm'

export type DictionaryMetaAttrs = {
  terms: DictTerm[]
}

export const DictionaryMeta = Node.create({
  name: 'dictionaryMeta',
  group: 'block',
  atom: true,
  selectable: false,
  defining: true,

  addAttributes() {
    return {
      terms: { default: [] },
    }
  },

  parseHTML() {
    return [
      {
        tag: 'miw-dict-meta',
        getAttrs: (el) => {
          const s = (el as HTMLElement).getAttribute('data-terms') || '[]'
          try { return { terms: JSON.parse(s) } } catch { return { terms: [] } }
        },
      },
    ]
  },

  renderHTML({ HTMLAttributes }) {
    const attrs = mergeAttributes({
      'data-terms': JSON.stringify(HTMLAttributes.terms || []),
      style: 'display:none',
    })
    return ['miw-dict-meta', attrs]
  },
})

export function extractDictionaryTermsFromJSON(json: any): DictTerm[] {
  try {
    const list: DictTerm[] = []
    const nodes: any[] = json?.content || []
    for (const n of nodes) {
      if (n?.type === 'dictionaryMeta') {
        const terms = (n.attrs?.terms || []) as DictTerm[]
        if (Array.isArray(terms)) {

          return terms
        }
      }
    }

    return list
  } catch {

    return []
  }
}

export function upsertDictionaryMetaInEditor(editor: Editor, terms: DictTerm[]) {
  // replace existing node or insert one at end
  const { state } = editor.view
  const { schema } = state
  const type = schema.nodes['dictionaryMeta']
  if (!type) return
  const tr = state.tr
  let foundPos: number | null = null
  state.doc.descendants((node, pos) => {
    if (node.type === type) { foundPos = pos; return false }
    return true
  })
  const node = type.create({ terms })
  if (foundPos != null) {
    tr.replaceWith(foundPos, foundPos + 1, node)
  } else {
    tr.insert(state.doc.content.size, node)
  }
  if (tr.docChanged) {
    editor.view.dispatch(tr)

  }
}


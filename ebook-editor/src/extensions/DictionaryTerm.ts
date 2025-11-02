import { Mark, markInputRule, markPasteRule, mergeAttributes } from '@tiptap/core'
import type { Editor } from '@tiptap/react'
import { Plugin, PluginKey } from 'prosemirror-state'
import type { EditorView } from 'prosemirror-view'

export type DictTerm = {
  id: string
  term: string
  definition: string
}

export const DictionaryTerm = Mark.create({
  name: 'dictionaryTerm',

  priority: 1001,

  addAttributes() {
    return {
      id: { default: null },
      term: { default: null },
    }
  },

  parseHTML() {
    return [
      {
        tag: 'span[data-dict-id]'
      },
    ]
  },

  renderHTML({ HTMLAttributes }) {
    return ['span', mergeAttributes(HTMLAttributes, { 'data-dict-id': HTMLAttributes.id, 'data-dict-term': HTMLAttributes.term, class: 'miw-dict-link' }), 0]
  },

  addProseMirrorPlugins() {
    const key = new PluginKey('miw-dict-click')
    return [
      new Plugin({
        key,
        props: {
          handleClick(view: EditorView, pos: number, event: MouseEvent) {
            const target = event.target as HTMLElement | null
            // 1) Prefer DOM dataset when available for robustness
            const host = target?.closest?.('[data-dict-id]') as HTMLElement | null
            if (host) {
              const id = host.getAttribute('data-dict-id') || ''
              const term = host.getAttribute('data-dict-term') || ''
              const rect = host.getBoundingClientRect()
              if (id && rect) {
                const detail = { id, term, rect: { left: rect.left, top: rect.top, width: rect.width, height: rect.height } }
                window.dispatchEvent(new CustomEvent('miw:dict-popup', { detail }))
                return true
              }
            }
            // 2) Fallback: derive from marks at click position
            const $pos = view.state.doc.resolve(pos)
            const marks = $pos.marks()
            const dictMark = marks.find(m => m.type.name === 'dictionaryTerm')
            if (!dictMark) return false
            const id = dictMark.attrs.id as string
            const term = dictMark.attrs.term as string
            const rect = target?.getBoundingClientRect?.()
            if (id && rect) {
              const detail = { id, term, rect: { left: rect.left, top: rect.top, width: rect.width, height: rect.height } }
              window.dispatchEvent(new CustomEvent('miw:dict-popup', { detail }))
              return true
            }
            return false
          }
        }
      })
    ]
  },
})

// Helper: generate id
function makeId() { return 'd_' + Math.random().toString(36).slice(2) + Date.now().toString(36) }

function isLatinWordChar(ch: string) {
  return /[A-Za-z0-9_]/.test(ch)
}

// Basic CJK block (Unified Ideographs). This is a pragmatic approximation.
function isCjkChar(ch: string) {
  return /[\u4E00-\u9FFF]/.test(ch)
}

function isWordBoundaryAround(source: string, start: number, end: number, term: string) {
  // If the term contains any CJK, require non-CJK on both sides (or boundaries)
  const hasCjk = /[\u4E00-\u9FFF]/.test(term)
  const prev = start > 0 ? source[start - 1] : ''
  const next = end < source.length ? source[end] : ''
  if (hasCjk) {
    // For CJK, allow matches anywhere and rely on longest-match-first + occupied ranges
    // to prevent shorter terms from overriding longer ones. This keeps terms like
    // “华商们” matchable in continuous sentences while avoiding “经济学” when a longer
    // “华商经济学” is also present.
    return true
  }
  // Latin-like: require non-letter/digit/underscore on both sides (or boundary)
  const prevOk = !prev || !isLatinWordChar(prev)
  const nextOk = !next || !isLatinWordChar(next)
  return prevOk && nextOk
}

export function linkAllTerms(editor: Editor, terms: DictTerm[]) {
  if (!editor || !terms?.length) return
  const { state } = editor.view
  const { schema } = state
  const dictMarkType = schema.marks['dictionaryTerm']
  const linkMarkType = schema.marks['link']
  if (!dictMarkType) return

  const sorted = [...terms].sort((a, b) => b.term.length - a.term.length)

  editor.view.dispatch(state.tr.setMeta('addToHistory', false)) // no-op write to ensure mapping

  let tr = state.tr
  let added = 0
  state.doc.descendants((node, pos) => {
    if (!node.isText) return true
    const text = node.text || ''
    const lower = text.toLowerCase()

    let occupied: [number, number][] = [] // local node ranges already marked to avoid overlaps

    for (const t of sorted) {
      if (!t.term) continue
      const needle = t.term.toLowerCase()
      if (!needle) continue

      let idx = 0
      while (true) {
        idx = lower.indexOf(needle, idx)
        if (idx === -1) break
        const from = pos + idx
        const to = from + t.term.length

        // boundary check
        if (!isWordBoundaryAround(text, idx, idx + t.term.length, t.term)) {
          idx = idx + needle.length
          continue
        }

        // overlap check within this node
        const overlaps = occupied.some(([a, b]) => !(to <= a || from >= b))
        if (overlaps) { idx = idx + needle.length; continue }

        // skip if inside existing link or dictionaryTerm
        const hasDict = dictMarkType && state.doc.rangeHasMark(from, to, dictMarkType)
        const hasLink = linkMarkType && state.doc.rangeHasMark(from, to, linkMarkType)
        if (hasDict || hasLink) { idx = idx + needle.length; continue }

        // add mark
        tr = tr.addMark(from, to, dictMarkType.create({ id: t.id || makeId(), term: t.term }))
        added++
        occupied.push([from, to])
        idx = idx + needle.length
      }
    }
    return true
  })

  if (tr.docChanged) {
    editor.view.dispatch(tr)

  } else {

  }
}

export function removeAllDictionaryMarksById(editor: Editor, id: string) {
  if (!editor || !id) return
  const { state } = editor.view
  const { schema } = state
  const dictMarkType = schema.marks['dictionaryTerm']
  if (!dictMarkType) return
  let tr = state.tr
  state.doc.descendants((node, pos) => {
    if (!node.isText) return true
    const text = node as any
    const marks = node.marks || []
    marks.forEach(m => {
      if (m.type === dictMarkType && m.attrs?.id === id) {
        const from = pos
        const to = pos + (node.text?.length || 0)
        // remove any dict marks with this id overlapping this text node
        node.marks.forEach(mark => {
          if (mark.type === dictMarkType && mark.attrs?.id === id) {
            tr = tr.removeMark(from, to, dictMarkType)
          }
        })
      }
    })
    return true
  })
  if (tr.docChanged) editor.view.dispatch(tr)
}


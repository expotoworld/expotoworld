import React, { useEffect, useMemo, useRef, useState } from 'react'
import type { Editor } from '@tiptap/react'
import debounce from 'lodash.debounce'
import { useTranslation } from 'react-i18next'
import { nanoid } from 'nanoid'

interface FlatHeading { id: string; level: number; text: string }
interface HeadingNode extends FlatHeading { children: HeadingNode[] }

function extractHeadings(editor: Editor | null): FlatHeading[] {
  const out: FlatHeading[] = []
  if (!editor) return out
  editor.state.doc.descendants((node) => {
    if (node.type.name === 'heading') {
      const id = (node.attrs as any)?.id as string | undefined
      const level = (node.attrs as any)?.level as number | undefined
      const text = node.textContent || ''
      if (id && level) out.push({ id, level, text })
    }
  })
  return out
}

function buildTree(items: FlatHeading[]): HeadingNode[] {
  const root: HeadingNode[] = []
  const stack: HeadingNode[] = []
  for (const item of items) {
    const node: HeadingNode = { ...item, children: [] }
    while (stack.length && stack[stack.length - 1].level >= node.level) stack.pop()
    if (stack.length === 0) root.push(node)
    else stack[stack.length - 1].children.push(node)
    stack.push(node)
  }
  return root
}

function scrollToId(id: string) {
  const el = document.getElementById(id)
  if (!el) return
  el.scrollIntoView({ behavior: 'smooth', block: 'center' })
}

export default function OutlineSidebar({ editor, open }: { editor: Editor | null; open: boolean }) {
  const { t } = useTranslation()
  const [flat, setFlat] = useState<FlatHeading[]>([])
  const [activeId, setActiveId] = useState<string | null>(null)
  const [collapsed, setCollapsed] = useState<Record<string, boolean>>({})
  const ioRef = useRef<IntersectionObserver | null>(null)

  // Build tree memoized
  const tree = useMemo(() => buildTree(flat), [flat])

  // Ensure headings have IDs and update list on editor changes (debounced)
  useEffect(() => {
    if (!editor) return

    const ensureIds = () => {
      const { state, view } = editor
      let tr = state.tr
      let changed = false
      const used = new Set<string>()

      state.doc.descendants((node, pos) => {
        if (node.type.name !== 'heading') return
        const attrs: any = { ...node.attrs }
        let id: string | null = attrs.id || null
        if (id && used.has(id)) id = null
        if (!id) {
          id = `h.${nanoid(8)}`
          tr = tr.setNodeMarkup(pos, undefined, { ...attrs, id })
          changed = true
        }
        if (id) used.add(id)
      })
      if (changed) view.dispatch(tr)
    }

    const run = () => {
      ensureIds()
      const list = extractHeadings(editor)
      // dev log removed
      setFlat(list)
    }

    const debounced = debounce(run, 120)
    run()
    // Listen to multiple events including 'transaction' so silent setContent updates are captured
    editor.on('update', debounced)
    editor.on('selectionUpdate', debounced)
    editor.on('transaction', debounced as any)
    return () => {
      editor.off('update', debounced)
      editor.off('selectionUpdate', debounced)
      editor.off('transaction', debounced as any)
      debounced.cancel()
    }
  }, [editor])

  // Also refresh headings when the sidebar is opened
  useEffect(() => {
    if (!editor || !open) return
    const list = extractHeadings(editor)
    setFlat(list)
  }, [open, editor])

  // Track active heading using scroll position: choose the heading nearest to the top.
  useEffect(() => {
    if (!open) return

    let raf = 0
    const compute = () => {
      raf = 0
      let bestId: string | null = null
      let bestTop = Number.POSITIVE_INFINITY
      const above: Array<{ id: string; top: number }> = []

      for (const h of flat) {
        const el = document.getElementById(h.id)
        if (!el) continue
        const top = el.getBoundingClientRect().top
        if (top >= 0) {
          if (top < bestTop) { bestTop = top; bestId = h.id }
        } else {
          above.push({ id: h.id, top })
        }
      }
      if (!bestId && above.length) {
        // pick the one just above the viewport (max top among negatives)
        above.sort((a, b) => b.top - a.top)
        bestId = above[0].id
      }
      if (bestId) setActiveId(prev => (prev === bestId ? prev : bestId))
    }

    const onScroll = () => { if (!raf) raf = requestAnimationFrame(compute) }
    window.addEventListener('scroll', onScroll, { passive: true })
    window.addEventListener('resize', onScroll)
    // initial compute
    compute()

    return () => {
      if (raf) cancelAnimationFrame(raf)
      window.removeEventListener('scroll', onScroll)
      window.removeEventListener('resize', onScroll)
    }
  }, [open, flat])

  if (!open) return null

  return (
    <aside className="miw-outline-sidebar" role="complementary" aria-label={t('outline.header')}>
      <div className="miw-outline-header"><strong>{t('outline.header')}</strong></div>
      <div className="miw-outline-list" role="tree">
        {tree.map(node => (
          <OutlineItem key={node.id} node={node} activeId={activeId} collapsed={collapsed} setCollapsed={setCollapsed} />
        ))}
      </div>
    </aside>
  )
}

function OutlineItem({ node, activeId, collapsed, setCollapsed }: { node: HeadingNode; activeId: string | null; collapsed: Record<string, boolean>; setCollapsed: React.Dispatch<React.SetStateAction<Record<string, boolean>>> }) {
  const isActive = node.id === activeId
  const hasChildren = node.children.length > 0
  const isCollapsed = !!collapsed[node.id]
  return (
    <div className={`miw-outline-item${isActive ? ' is-active' : ''}`} role="treeitem" aria-expanded={!isCollapsed}>
      <div className="miw-outline-row" style={{ paddingLeft: (node.level - 1) * 14 }}>
        {hasChildren ? (
          <button className="miw-outline-toggle" aria-label={isCollapsed ? 'Expand' : 'Collapse'} onClick={() => setCollapsed(s => ({ ...s, [node.id]: !s[node.id] }))}>
            <span aria-hidden>{isCollapsed ? '▸' : '▾'}</span>
          </button>
        ) : (
          <span className="miw-outline-spacer" aria-hidden />
        )}
        <button className="miw-outline-link" onClick={() => scrollToId(node.id)}>
          <span className={`miw-outline-l${node.level}`}>{node.text || `Heading ${node.level}`}</span>
        </button>
      </div>
      {!isCollapsed && node.children.length > 0 && (
        <div role="group">
          {node.children.map(ch => (
            <OutlineItem key={ch.id} node={ch} activeId={activeId} collapsed={collapsed} setCollapsed={setCollapsed} />
          ))}
        </div>
      )}
    </div>
  )
}


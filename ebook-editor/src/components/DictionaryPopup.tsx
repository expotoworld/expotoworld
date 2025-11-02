import React, { useEffect, useRef, useState } from 'react'
import type { DictTerm } from '../extensions/DictionaryTerm'
import { useTranslation } from 'react-i18next'

export function DictionaryPopup({ terms }: { terms: DictTerm[] }) {
  const [open, setOpen] = useState(false)
  const [data, setData] = useState<{ id: string, term: string, rect: { left: number, top: number, width: number, height: number } } | null>(null)
  const rootRef = useRef<HTMLDivElement>(null)
  const closeBtnRef = useRef<HTMLButtonElement>(null)
  const prevFocusRef = useRef<HTMLElement | null>(null)
  const titleId = 'miw-dict-title'
  const bodyId = 'miw-dict-body'
  const doClose = () => {
    setOpen(false)
    setTimeout(() => {
      const prev = prevFocusRef.current
      if (prev && document.contains(prev)) prev.focus()
      else {
        const pm = document.querySelector('.ProseMirror') as HTMLElement | null
        pm?.focus?.()
      }
    }, 0)
  }

  const { t } = useTranslation()

  const termsRef = useRef<DictTerm[]>([])
  useEffect(() => { termsRef.current = terms }, [terms])

  useEffect(() => {
    function onShow(e: Event) {
      const detail = (e as CustomEvent).detail as any
      const found = termsRef.current.find(t => t.id === detail.id)
      if (!found) return
      prevFocusRef.current = (document.activeElement as HTMLElement) || null
      setData(detail)
      setOpen(true)
      setTimeout(() => { closeBtnRef.current?.focus() }, 0)
    }
    window.addEventListener('miw:dict-popup' as any, onShow)
    return () => {
      window.removeEventListener('miw:dict-popup' as any, onShow)
    }
  }, [])

  useEffect(() => {
    const onScroll = (e: Event) => {
      // Close only when the PAGE/VIEWPORT scrolls, not when the popup itself scrolls
      if (!open) return
      const target = e.target as HTMLElement | null
      if (target && rootRef.current && rootRef.current.contains(target)) return
      doClose()
    }
    const onResize = () => { if (open) doClose() }
    const onClick = (ev: MouseEvent) => {
      if (!open) return
      if (!rootRef.current) return
      if (!rootRef.current.contains(ev.target as Node)) doClose()
    }
    window.addEventListener('scroll', onScroll, true)
    window.addEventListener('resize', onResize)
    document.addEventListener('mousedown', onClick)
    return () => {
      window.removeEventListener('scroll', onScroll, true)
      window.removeEventListener('resize', onResize)
      document.removeEventListener('mousedown', onClick)
    }
  }, [open])

  if (!open || !data) return null

  const termEntry = terms.find(x => x.id === data.id)
  const definition = termEntry?.definition || '—'
  const title = termEntry?.term || data.term

  // Position: prefer above; if not enough space, below. Fixed size.
  const width = 380
  const height = 220
  const gap = 8
  const vw = window.innerWidth, vh = window.innerHeight
  let left = Math.min(Math.max(data.rect.left + data.rect.width / 2 - width / 2, 8), vw - width - 8)
  let top = data.rect.top - gap - height
  if (top < 8) top = Math.min(data.rect.top + data.rect.height + gap, vh - height - 8)

  return (
    <div
      ref={rootRef}
      className="miw-dict-popup"
      role="dialog"
      aria-modal="true"
      aria-labelledby={titleId}
      aria-describedby={bodyId}
      tabIndex={-1}
      onKeyDown={(e) => {
        if (e.key === 'Escape') { e.stopPropagation(); doClose(); return }
        if (e.key === 'Tab') {
          const root = rootRef.current
          if (!root) return
          const focusable = Array.from(root.querySelectorAll<HTMLElement>('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'))
            .filter(el => !el.hasAttribute('disabled'))
          if (focusable.length === 0) return
          const first = focusable[0]
          const last = focusable[focusable.length - 1]
          if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus() }
          else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus() }
        }
      }}
      style={{ position: 'fixed', left, top, width, height, zIndex: 2010 }}
    >
      <div className="miw-dict-popup-header">
        <div className="miw-dict-popup-title" id={titleId} title={title}>{title}</div>
        <button ref={closeBtnRef} className="miw-dict-popup-close" onClick={doClose} aria-label={t('common.close') || 'Close'}>×</button>
      </div>
      <div className="miw-dict-popup-body" id={bodyId}>
        {definition}
      </div>
    </div>
  )
}


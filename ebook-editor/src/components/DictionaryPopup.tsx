import React, { useEffect, useRef, useState } from 'react'
import type { DictTerm } from '../extensions/DictionaryTerm'
import { useTranslation } from 'react-i18next'

export function DictionaryPopup({ terms }: { terms: DictTerm[] }) {
  const [open, setOpen] = useState(false)
  const [data, setData] = useState<{ id: string, term: string, rect: { left: number, top: number, width: number, height: number } } | null>(null)
  const rootRef = useRef<HTMLDivElement>(null)
  const { t } = useTranslation()

  useEffect(() => {
    function onShow(e: Event) {
      const detail = (e as CustomEvent).detail as any
      setData(detail)
      setOpen(true)
    }
    window.addEventListener('miw:dict-popup' as any, onShow)
    const onScroll = (e: Event) => {
      // Close only when the PAGE/VIEWPORT scrolls, not when the popup itself scrolls
      if (!open) return
      const target = e.target as HTMLElement | null
      if (target && rootRef.current && rootRef.current.contains(target)) return
      setOpen(false)
    }
    window.addEventListener('scroll', onScroll, true)
    const onResize = () => { if (open) setOpen(false) }
    window.addEventListener('resize', onResize)
    const onClick = (ev: MouseEvent) => {
      if (!rootRef.current) return
      if (!rootRef.current.contains(ev.target as Node)) setOpen(false)
    }
    document.addEventListener('mousedown', onClick)
    return () => {
      window.removeEventListener('miw:dict-popup' as any, onShow)
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
    <div ref={rootRef} className="miw-dict-popup" style={{ position: 'fixed', left, top, width, height, zIndex: 2010 }}>
      <div className="miw-dict-popup-header">
        <div className="miw-dict-popup-title" title={title}>{title}</div>
        <button className="miw-dict-popup-close" onClick={() => setOpen(false)} aria-label={t('common.close') || 'Close'}>×</button>
      </div>
      <div className="miw-dict-popup-body">
        {definition}
      </div>
    </div>
  )
}


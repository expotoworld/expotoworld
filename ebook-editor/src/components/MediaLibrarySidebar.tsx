import React, { useEffect, useMemo, useRef, useState } from 'react'
import axios from 'axios'

const API_BASE = (import.meta as any).env?.VITE_API_BASE || 'https://device-api.expotoworld.com'

type Item = { media_key: string; in_autosave: boolean; manual_refs: number; published_refs: number; last_seen_at: string }

function filename(key: string) { const p = key.split('/'); return p[p.length - 1] }

export default function MediaLibrarySidebar({ token, open, onClose, onInspect }: { token: string; open: boolean; onClose: () => void; onInspect: (key: string) => void }) {
  const [items, setItems] = useState<Item[]>([])
  const [loading, setLoading] = useState(false)
  const [filters, setFilters] = useState<{ all: boolean; autosave: boolean; manual: boolean; published: boolean }>({ all: true, autosave: false, manual: false, published: false })
  const headers = useMemo(() => ({ Authorization: `Bearer ${token}` }), [token])
  const ref = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!open) return
    let cancelled = false
    async function fetchList() {
      setLoading(true)
      try {
        const params: any = {}
        if (!filters.all) {
          if (filters.autosave) params.autosave = '1'
          if (filters.manual) params.manual = '1'
          if (filters.published) params.published = '1'
        }
        const res = await axios.get(`${API_BASE}/api/ebook/admin/media-list`, { headers, params })
        if (!cancelled) setItems(res.data?.items || [])
      } catch (e) { if (!cancelled) setItems([]) } finally { if (!cancelled) setLoading(false) }
    }
    fetchList()
  }, [open, filters])

  useEffect(() => {
    if (!open) return
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape') onClose() }
    const onClick = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        const wc = document.querySelector('.wc-root')
        if (wc && (wc === e.target || (e.target as Node).nodeType === 1 && (e.target as HTMLElement).closest('.wc-root'))) {
          onClose(); return
        }
        onClose()
      }
    }
    document.addEventListener('keydown', onKey)
    document.addEventListener('mousedown', onClick)
    return () => { document.removeEventListener('keydown', onKey); document.removeEventListener('mousedown', onClick) }
  }, [open])

  if (!open) return null

  const chip = (label: string, active: boolean, onClick: () => void) => (
    <button className={`miw-chip ${active ? 'is-active' : ''}`} onClick={onClick}>{label}</button>
  )

  const tags = (it: Item) => {
    const inAuto = it.in_autosave
    const inManual = it.manual_refs > 0
    const inPub = it.published_refs > 0
    if (inAuto && inManual && inPub) return [<span key="all" className="miw-tag all">All</span>]
    const t: JSX.Element[] = []
    if (inAuto) t.push(<span key="a" className="miw-tag autosave">Autosave</span>)
    if (inManual) t.push(<span key="m" className="miw-tag manual">Manual</span>)
    if (inPub) t.push(<span key="p" className="miw-tag published">Published</span>)
    return t
  }

  const filtered = items.filter(it => {
    if (filters.all) return true
    let ok = false
    if (filters.autosave && it.in_autosave) ok = true
    if (filters.manual && it.manual_refs > 0) ok = true
    if (filters.published && it.published_refs > 0) ok = true
    return ok
  })

  return (
    <div className="miw-sidebar-veil">
      <aside ref={ref} className="miw-sidebar">
        <div className="miw-sidebar-header">
          <strong>Media Library</strong>
          <button className="miw-close" onClick={onClose} aria-label="Close">&times;</button>
        </div>
        <div className="miw-sidebar-filters">
          {chip('All', filters.all, () => setFilters({ all: true, autosave: false, manual: false, published: false }))}
          {chip('Autosave', filters.autosave, () => setFilters(f => ({ ...f, all: false, autosave: !f.autosave })))}
          {chip('Manual', filters.manual, () => setFilters(f => ({ ...f, all: false, manual: !f.manual })))}
          {chip('Published', filters.published, () => setFilters(f => ({ ...f, all: false, published: !f.published })))}
        </div>
        <div className="miw-sidebar-list">
          {loading && <div style={{ padding: 8 }}>Loading...</div>}
          {!loading && filtered.length === 0 && <div style={{ padding: 8, color: 'var(--color-muted)' }}>No files</div>}
          {!loading && filtered.map(it => (
            <button key={it.media_key} className="miw-media-row" onClick={() => onInspect(it.media_key)}>
              <span className="miw-media-name">{filename(it.media_key)}</span>
              <span className="miw-media-tags">{tags(it)}</span>
            </button>
          ))}
        </div>
      </aside>
    </div>
  )
}


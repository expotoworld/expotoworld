import React, { useEffect, useMemo, useState } from 'react'
import axios from 'axios'
import { Modal } from './Modal'

const API_BASE = (import.meta as any).env?.VITE_API_BASE || 'https://device-api.expotoworld.com'

function fmt(ts: string | Date) {
  const d = new Date(ts)
  return d.toLocaleString(undefined, { month: 'short', day: '2-digit', year: 'numeric', hour: 'numeric', minute: '2-digit' })
}

function filenameFromKey(key: string) {
  const p = key.split('/')
  return p[p.length - 1]
}

export default function PendingModal({ token, open, onClose }: { token: string; open: boolean; onClose: () => void }) {
  const [items, setItems] = useState<Array<any>>([])
  const [loading, setLoading] = useState(false)
  const [page, setPage] = useState(0)
  const limit = 20

  const headers = useMemo(() => ({ Authorization: `Bearer ${token}` }), [token])

  useEffect(() => {
    if (!open) return
    let cancelled = false

    const fetchData = async (showSpinner: boolean) => {
      if (showSpinner) setLoading(true)
      try {
        const res = await axios.get(`${API_BASE}/api/ebook/admin/pending`, { headers, params: { limit, offset: page * limit } })
        if (!cancelled) setItems(res.data?.items || [])
      } catch (e) {
        if (!cancelled) setItems([])
      } finally { if (!cancelled && showSpinner) setLoading(false) }
    }

    // Initial load with spinner
    fetchData(true)
    // Background refresh without toggling layout
    const id = setInterval(() => fetchData(false), 5000)
    return () => { cancelled = true; clearInterval(id) }
  }, [open, page])

  // tick for countdowns
  const [, setTick] = useState(0)
  useEffect(() => { if (!open) return; const id = setInterval(() => setTick(t => t + 1), 1000); return () => clearInterval(id) }, [open])

  const now = Date.now()
  const showPager = page > 0 || items.length === limit

  const goPrev = () => { if (page > 0) setPage(p => p - 1) }
  const goNext = () => { if (items.length === limit) setPage(p => p + 1) }

  return (
    <Modal open={open} title="Pending Deletions" onClose={onClose} width={760}>
      <div style={{ minWidth: 640 }}>
        {loading && <div style={{ padding: 8, fontSize: 14 }}>Loading...</div>}
        {(!loading && items.length === 0) && <div style={{ padding: 12, color: 'var(--color-muted)' }}>No files pending deletion</div>}
        {items.length > 0 && (
          <div style={{ overflowX: 'auto' }}>
            <table className="miw-table" style={{ minWidth: 680 }}>
              <thead><tr>
                <th style={{ textAlign: 'left' }}>File Name</th>
                <th>Requested At</th>
                <th>Time Until Deletion</th>
                <th>Attempts</th>
              </tr></thead>
              <tbody>
                {items.map((it: any) => {
                  const nb = new Date(it.not_before).getTime()
                  const diffMs = nb - now
                  const overdue = diffMs <= 0
                  let countdown = ''
                  if (overdue) countdown = 'Ready for deletion'
                  else {
                    const s = Math.floor(diffMs / 1000)
                    const mm = Math.floor(s / 60)
                    const ss = s % 60
                    countdown = `${mm}m ${ss}s`
                  }
                  return (
                    <tr key={it.media_key}>
                      <td style={{ textAlign: 'left', wordBreak: 'break-all' }}>{filenameFromKey(it.media_key)}</td>
                      <td>{fmt(it.requested_at)}</td>
                      <td>{countdown}</td>
                      <td>{it.attempts}</td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
            {showPager && (
              <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 8 }}>
                <button className="secondary-btn" onClick={goPrev} disabled={page === 0}>Prev</button>
                <span style={{ fontSize: 12, color: 'var(--color-muted)' }}>Page {page + 1}</span>
                <button className="secondary-btn" onClick={goNext} disabled={items.length < limit}>Next</button>
              </div>
            )}
          </div>
        )}
      </div>
    </Modal>
  )
}


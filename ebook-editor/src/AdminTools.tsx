import React, { useEffect, useMemo, useRef, useState } from 'react'
import axios from 'axios'
import { ConfirmDialog, Modal } from './components/Modal'
import PendingModal from './components/PendingModal'
import MediaLibrarySidebar from './components/MediaLibrarySidebar'

const API_BASE = (import.meta as any).env?.VITE_API_BASE || 'https://device-api.expotoworld.com'

const Icons = {
  Tools: (
    <svg className="miw-ico" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M5.32943 3.27158C6.56252 2.8332 7.9923 3.10749 8.97927 4.09446C9.96652 5.08171 10.2407 6.51202 9.80178 7.74535L20.6465 18.5902L18.5252 20.7115L7.67936 9.86709C6.44627 10.3055 5.01649 10.0312 4.02952 9.04421C3.04227 8.05696 2.7681 6.62665 3.20701 5.39332L5.44373 7.63C6.02952 8.21578 6.97927 8.21578 7.56505 7.63C8.15084 7.04421 8.15084 6.09446 7.56505 5.50868L5.32943 3.27158ZM15.6968 5.15512L18.8788 3.38736L20.293 4.80157L18.5252 7.98355L16.7574 8.3371L14.6361 10.4584L13.2219 9.04421L15.3432 6.92289L15.6968 5.15512ZM8.62572 12.9333L10.747 15.0546L5.79729 20.0044C5.2115 20.5902 4.26175 20.5902 3.67597 20.0044C3.12464 19.453 3.09221 18.5793 3.57867 17.99L3.67597 17.883L8.62572 12.9333Z"></path></svg>
  ),
  Reindex: (
    <svg className="miw-ico" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M3.08697 9H20.9134C21.4657 9 21.9134 9.44772 21.9134 10C21.9134 10.0277 21.9122 10.0554 21.9099 10.083L21.0766 20.083C21.0334 20.6013 20.6001 21 20.08 21H3.9203C3.40021 21 2.96695 20.6013 2.92376 20.083L2.09042 10.083C2.04456 9.53267 2.45355 9.04932 3.00392 9.00345C3.03155 9.00115 3.05925 9 3.08697 9ZM4.84044 19H19.1599L19.8266 11H4.17377L4.84044 19ZM13.4144 5H20.0002C20.5525 5 21.0002 5.44772 21.0002 6V7H3.00017V4C3.00017 3.44772 3.44789 3 4.00017 3H11.4144L13.4144 5Z"></path></svg>
  ),
  Inspect: (
    <svg className="miw-ico" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M18.031 16.6168L22.3137 20.8995L20.8995 22.3137L16.6168 18.031C15.0769 19.263 13.124 20 11 20C6.032 20 2 15.968 2 11C2 6.032 6.032 2 11 2C15.968 2 20 6.032 20 11C20 13.124 19.263 15.0769 18.031 16.6168ZM16.0247 15.8748C17.2475 14.6146 18 12.8956 18 11C18 7.1325 14.8675 4 11 4C7.1325 4 4 7.1325 4 11C4 14.8675 7.1325 18 11 18C12.8956 18 14.6146 17.2475 15.8748 16.0247L16.0247 15.8748ZM12.1779 7.17624C11.4834 7.48982 11 8.18846 11 9C11 10.1046 11.8954 11 13 11C13.8115 11 14.5102 10.5166 14.8238 9.82212C14.9383 10.1945 15 10.59 15 11C15 13.2091 13.2091 15 11 15C8.79086 15 7 13.2091 7 11C7 8.79086 8.79086 7 11 7C11.41 7 11.8055 7.06167 12.1779 7.17624Z"></path></svg>
  ),
  Pending: (
    <svg className="miw-ico" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M20 7V20C20 21.1046 19.1046 22 18 22H6C4.89543 22 4 21.1046 4 20V7H2V5H22V7H20ZM6 7V20H18V7H6ZM11 9H13V11H11V9ZM11 12H13V14H11V12ZM11 15H13V17H11V15ZM7 2H17V4H7V2Z"></path></svg>
  )
}

export default function AdminTools({ token }: { token: string }) {
  const [open, setOpen] = useState(false)
  const rootRef = useRef<HTMLDivElement>(null)

  const [pendingOpen, setPendingOpen] = useState(false)
  const [inspectOpen, setInspectOpen] = useState(false)
  const [confirmOpen, setConfirmOpen] = useState(false)
  const [resultMsg, setResultMsg] = useState<string | null>(null)
  const [inspectData, setInspectData] = useState<any | null>(null)

  const headers = useMemo(() => ({ Authorization: `Bearer ${token}` }), [token])

  useEffect(() => {
    const onClickOutside = (e: MouseEvent) => {
      if (rootRef.current && !rootRef.current.contains(e.target as Node)) setOpen(false)
    }
    if (open) document.addEventListener('mousedown', onClickOutside)
    return () => document.removeEventListener('mousedown', onClickOutside)
  }, [open])

  return (
    <div ref={rootRef} className="dropdown" style={{ position: 'relative' }}>
      <button className="theme-toggle" onClick={() => setOpen(v => !v)} aria-label="Tools" title="Tools">
        {Icons.Tools}
      </button>
      {open && (
        <div className="dropdown-menu" role="menu" style={{ right: 0, left: 'auto', minWidth: 220 }}>
          <button className="dropdown-item" style={{ whiteSpace: 'nowrap' }} onClick={() => { setOpen(false); setConfirmOpen(true) }}>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 8 }}>{Icons.Reindex}<span>Re-index</span></span>
          </button>
          <button className="dropdown-item" style={{ whiteSpace: 'nowrap' }} onClick={() => { setOpen(false); setInspectOpen(true) }}>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 8 }}>{Icons.Inspect}<span>Inspect</span></span>
          </button>
          <button className="dropdown-item" style={{ whiteSpace: 'nowrap' }} onClick={() => { setOpen(false); setPendingOpen(true) }}>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 8 }}>{Icons.Pending}<span>Pending</span></span>
          </button>
        </div>
      )}

      <ConfirmDialog
        open={confirmOpen}
        title="Re-index"
        message="Re-index everything now?"
        onCancel={() => setConfirmOpen(false)}
        onConfirm={async () => {
          setConfirmOpen(false)
          try {
            await axios.post(`${API_BASE}/api/ebook/admin/reindex`, null, { headers })
            setResultMsg('Re-index complete')
          } catch (e) { setResultMsg('Re-index failed') }
        }}
      />

      <Modal open={!!resultMsg} title="Status" onClose={() => setResultMsg(null)}>
        <div>{resultMsg}</div>
      </Modal>

      <Modal open={!!inspectData} title="Media Info" onClose={() => setInspectData(null)}>
        {inspectData && (
          <table className="miw-table" style={{ width: '100%' }}>
            <tbody>
              <tr><th style={{ textAlign: 'left', width: '40%' }}>S3 Key</th><td style={{ wordBreak: 'break-all' }}>{inspectData.media_key}</td></tr>
              <tr><th style={{ textAlign: 'left' }}>Exists in DB</th><td>{inspectData.exists ? 'Yes' : 'No'}</td></tr>
              <tr><th style={{ textAlign: 'left' }}>Autosave</th><td>{inspectData.in_autosave ? 'Yes' : 'No'}</td></tr>
              <tr><th style={{ textAlign: 'left' }}>Manual refs</th><td>{inspectData.manual_refs || 0}</td></tr>
              <tr><th style={{ textAlign: 'left' }}>Published refs</th><td>{inspectData.published_refs || 0}</td></tr>
              <tr><th style={{ textAlign: 'left' }}>Last seen</th><td>{inspectData.last_seen_at || 'n/a'}</td></tr>
            </tbody>
          </table>
        )}
      </Modal>

      <PendingModal token={token} open={pendingOpen} onClose={() => setPendingOpen(false)} />

      <MediaLibrarySidebar
        token={token}
        open={inspectOpen}
        onClose={() => setInspectOpen(false)}
        onInspect={async (key: string) => {
          try {
            const res = await axios.get(`${API_BASE}/api/ebook/admin/inspect`, { headers, params: { target: key } })
            setInspectData(res.data)
          } catch {
            setResultMsg('Inspect failed')
          }
        }}
      />
    </div>
  )
}

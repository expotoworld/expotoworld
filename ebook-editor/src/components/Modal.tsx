import React, { useEffect } from 'react'

export function Modal({ open, title, onClose, children, width = 520 }: {
  open: boolean;
  title?: string;
  onClose: () => void;
  children: React.ReactNode;
  width?: number | string;
}) {
  useEffect(() => {
    if (!open) return
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape') onClose() }
    document.addEventListener('keydown', onKey)
    return () => document.removeEventListener('keydown', onKey)
  }, [open])

  if (!open) return null
  return (
    <div className="miw-modal-backdrop" onClick={onClose}>
      <div className="miw-modal-card" style={{ maxWidth: width }} onClick={e => e.stopPropagation()}>
        {title && (
          <div className="miw-modal-header">
            <h3>{title}</h3>
            <button className="miw-close" onClick={onClose} aria-label="Close">×</button>
          </div>
        )}
        <div className="miw-modal-body">{children}</div>
      </div>
    </div>
  )
}

export function ConfirmDialog({ open, title = 'Confirm', message, confirmText = 'Confirm', cancelText = 'Cancel', onConfirm, onCancel }: {
  open: boolean;
  title?: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  onConfirm: () => void;
  onCancel: () => void;
}) {
  return (
    <Modal open={open} title={title} onClose={onCancel}>
      <p style={{ margin: '8px 0 16px' }}>{message}</p>
      <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8 }}>
        <button className="secondary-btn" onClick={onCancel}>{cancelText}</button>
        <button className="primary-btn" onClick={onConfirm}>{confirmText}</button>
      </div>
    </Modal>
  )
}


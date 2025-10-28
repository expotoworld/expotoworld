import { Extension } from '@tiptap/core'
import { Plugin, PluginKey } from '@tiptap/pm/state'
import axios from 'axios'

const API_BASE = (import.meta as any).env?.VITE_API_BASE || 'https://device-api.expotoworld.com'

export interface ImageDeletionOptions {
  onImageDelete?: (imageUrl: string) => void
}

export const ImageDeletionExtension = Extension.create<ImageDeletionOptions>({
  name: 'imageDeletion',

  addOptions() {
    return {
      onImageDelete: undefined,
    }
  },

  addProseMirrorPlugins() {
    const { onImageDelete } = this.options

    return [
      new Plugin({
        key: new PluginKey('imageDeletion'),
        appendTransaction: (transactions, oldState, newState) => {
          // Track deleted images
          const deletedImages: string[] = []

          transactions.forEach((transaction) => {
            if (!transaction.docChanged) return

            // Find all images in the old document
            const oldImages = new Set<string>()
            oldState.doc.descendants((node) => {
              if (node.type.name === 'image' && node.attrs.src) {
                oldImages.add(node.attrs.src)
              }
            })

            // Find all images in the new document
            const newImages = new Set<string>()
            newState.doc.descendants((node) => {
              if (node.type.name === 'image' && node.attrs.src) {
                newImages.add(node.attrs.src)
              }
            })

            // Find images that were deleted
            oldImages.forEach((src) => {
              if (!newImages.has(src)) {
                deletedImages.push(src)
              }
            })
          })

          // Call the callback for each deleted image
          if (deletedImages.length > 0 && onImageDelete) {
            deletedImages.forEach((imageUrl) => {
              onImageDelete(imageUrl)
            })
          }

          return null
        },
      }),
    ]
  },
})

// Helper function to delete image from S3
export async function deleteImageFromS3(imageUrl: string): Promise<void> {
  try {
    const token = (() => {
      try {
        return JSON.parse(localStorage.getItem('ebook_token') || 'null')?.token || null
      } catch {
        return null
      }
    })()

    if (!token) {
      return
    }

    await axios.delete(`${API_BASE}/api/ebook/delete-image`, {
      data: { image_url: imageUrl },
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
    })

  } catch (error) {
    console.error('Failed to delete image from S3:', error)
    // Don't throw error - we don't want to interrupt the user's editing flow
  }
}


import { Node, mergeAttributes } from '@tiptap/core'

export interface VideoOptions {
  HTMLAttributes: Record<string, any>
}

declare module '@tiptap/core' {
  interface Commands<ReturnType> {
    video: {
      setVideo: (options: { src: string }) => ReturnType
    }
  }
}

export const VideoNode = Node.create<VideoOptions>({
  name: 'video',
  group: 'block',
  atom: true,
  draggable: true,
  selectable: true,

  addOptions() {
    return {
      HTMLAttributes: { controls: true, style: 'max-width:100%; height:auto;' },
    }
  },

  addAttributes() {
    return {
      src: { default: null },
    }
  },

  parseHTML() { return [{ tag: 'video' }] },

  renderHTML({ HTMLAttributes }) {
    return ['video', mergeAttributes(this.options.HTMLAttributes, HTMLAttributes)]
  },

  addCommands() {
    return {
      setVideo:
        ({ src }) => ({ commands }) =>
          commands.insertContent({ type: this.name, attrs: { src } }),
    }
  },
})


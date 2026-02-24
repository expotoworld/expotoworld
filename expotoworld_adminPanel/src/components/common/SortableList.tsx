/**
 * SortableList — a reusable drag-and-drop sortable wrapper built on @dnd-kit.
 * Provides both a container and a sortable item with drag handle.
 */
import React, { useCallback } from 'react';
import {
  DndContext,
  closestCenter,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  type DragEndEvent,
} from '@dnd-kit/core';
import {
  arrayMove,
  SortableContext,
  sortableKeyboardCoordinates,
  useSortable,
  verticalListSortingStrategy,
} from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { Box, IconButton } from '@mui/material';
import DragIndicatorIcon from '@mui/icons-material/DragIndicator';

// ============================================================
// SortableItem — wraps each draggable item
// ============================================================

interface SortableItemProps {
  id: string | number;
  children: React.ReactNode;
  disabled?: boolean;
}

export const SortableItem: React.FC<SortableItemProps> = ({ id, children, disabled }) => {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id, disabled });

  const style: React.CSSProperties = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
    position: 'relative' as const,
    zIndex: isDragging ? 999 : undefined,
  };

  return (
    <Box ref={setNodeRef} style={style} {...attributes}>
      <Box sx={{ display: 'flex', alignItems: 'center' }}>
        {!disabled && (
          <IconButton
            size="small"
            {...listeners}
            sx={{
              cursor: 'grab',
              '&:active': { cursor: 'grabbing' },
              mr: 0.5,
              touchAction: 'none',
            }}
          >
            <DragIndicatorIcon fontSize="small" color="action" />
          </IconButton>
        )}
        <Box sx={{ flex: 1, minWidth: 0 }}>{children}</Box>
      </Box>
    </Box>
  );
};

// ============================================================
// DragHandle — a standalone grab handle for sortable rows
// ============================================================

export const DragHandle: React.FC<{ listeners?: Record<string, unknown>; attributes?: Record<string, unknown> }> = ({
  listeners,
  attributes,
}) => (
  <IconButton
    size="small"
    {...listeners}
    {...attributes}
    sx={{
      cursor: 'grab',
      '&:active': { cursor: 'grabbing' },
      touchAction: 'none',
    }}
  >
    <DragIndicatorIcon fontSize="small" color="action" />
  </IconButton>
);

export const useSortableRow = (id: string | number, disabled?: boolean) => {
  return useSortable({ id, disabled });
};

// ============================================================
// SortableList — the container that manages drag context
// ============================================================

interface SortableListProps<T extends { id: string | number }> {
  items: T[];
  onReorder: (reorderedItems: T[]) => void;
  renderItem: (item: T, index: number) => React.ReactNode;
  disabled?: boolean;
}

export function SortableList<T extends { id: string | number }>({
  items,
  onReorder,
  renderItem,
  disabled,
}: SortableListProps<T>) {
  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: { distance: 5 },
    }),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    })
  );

  const handleDragEnd = useCallback(
    (event: DragEndEvent) => {
      const { active, over } = event;
      if (!over || active.id === over.id) return;

      const oldIndex = items.findIndex((item) => item.id === active.id);
      const newIndex = items.findIndex((item) => item.id === over.id);
      if (oldIndex === -1 || newIndex === -1) return;

      const reordered = arrayMove(items, oldIndex, newIndex);
      onReorder(reordered);
    },
    [items, onReorder]
  );

  return (
    <DndContext sensors={sensors} collisionDetection={closestCenter} onDragEnd={handleDragEnd}>
      <SortableContext
        items={items.map((item) => item.id)}
        strategy={verticalListSortingStrategy}
        disabled={disabled}
      >
        {items.map((item, index) => renderItem(item, index))}
      </SortableContext>
    </DndContext>
  );
}

// Re-export utilities for custom implementations
export { arrayMove } from '@dnd-kit/sortable';
export {
  DndContext,
  closestCenter,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
} from '@dnd-kit/core';
export {
  SortableContext,
  sortableKeyboardCoordinates,
  verticalListSortingStrategy,
} from '@dnd-kit/sortable';
export { CSS } from '@dnd-kit/utilities';
export type { DragEndEvent } from '@dnd-kit/core';

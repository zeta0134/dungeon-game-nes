IRQ_TABLE_SIZE = 128
.globalzp active_irq_index, inactive_irq_index
.global irq_table_scanlines, irq_table_nametable_high, irq_table_scroll_y, irq_table_scroll_x, irq_table_nametable_low, irq_table_ppumask, irq_table_chr0_bank
.global irq
.global initialize_irq_table, swap_irq_buffers, setup_irq_table_for_frame

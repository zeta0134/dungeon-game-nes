.ifndef IRQ_INC
.define IRQ_INC 1

IRQ_TABLE_SIZE = 128
.importzp active_irq_index, inactive_irq_index
.import irq_table_scanlines, irq_table_nametable_high, irq_table_scroll_y, irq_table_scroll_x, irq_table_nametable_low, irq_table_ppumask, irq_table_chr0_bank
.import irq
.import initialize_irq_table, swap_irq_buffers
.endif
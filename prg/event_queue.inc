MAX_EVENTS = 8
EVENT_INDEX_MASK = $7

.global event_current, event_next

.global events_type
.global events_pos_x
.global events_pos_y
.global events_id
.global events_data1
.global events_data2
.global events_data3
.global events_data4
.global events_data5

.global add_event, consume_event
extends Node

signal phase_changed(phase: int)
signal soup_served(cup: RefCounted, result: RefCounted)
signal water_added
signal pot_emptied
signal customer_arrived(customer: RefCounted)
signal customer_left(customer: RefCounted)
signal reputation_changed(value: int)
signal day_ended(day: int)

extends Node3D
class_name ArmParticles

@export var dont_color : Array[GPUParticles3D]

var color : Color
var finished_particles : int = 0


func emit_particles():
	for child in get_children():
		var particle : GPUParticles3D = child
		
		particle.finished.connect(count_finished.bind(particle))
		
		if not child in dont_color:
			particle.draw_pass_1.surface_get_material(0).albedo_color = color * 3
		
		particle.one_shot = true
		particle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		particle.emitting = true


func count_finished(_particle):
	finished_particles += 1
	if finished_particles >= get_child_count():
		queue_free()

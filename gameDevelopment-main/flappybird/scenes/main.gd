extends Node

@export var pipe_scene : PackedScene

var is_game_running : bool
var is_game_over : bool
var background_scroll
var current_score
const BACKGROUND_SCROLL_SPEED : int = 4
var screen_dimensions : Vector2i
var tile_dimensions : Vector2 = Vector2(16, 16)
var ground_dimensions : Rect2
var ground_y_offset : float
var active_pipes : Array
const PIPE_SPAWN_DELAY : int = 100
const PIPE_POSITION_RANGE : int = 200
var is_game_over_sound_playing: bool = false
var final_score_display : Label
var is_start_pressed = false

func _ready():
	screen_dimensions = get_window().size
	ground_dimensions = $Ground.get_node("TileMap").get_used_rect()
	ground_y_offset = ground_dimensions.size.y * tile_dimensions.y
	final_score_display = $GameOver.get_node("ScoreLabelFinal")
	start_new_game()

func start_new_game():
	is_game_running = false
	is_game_over = false
	current_score = 0
	background_scroll = 0
	$ScoreLabel.show()
	final_score_display.hide()
	$ScoreLabel.text = "SCORE: " + str(current_score)
	final_score_display.text = "SCORE: " + str(current_score)
	$GameOver.hide()
	get_tree().call_group("pipes", "queue_free")
	active_pipes.clear()
	create_pipes()
	$Bird.initialize()
	$Beggining.show()

func _input(event):
	if not is_game_over:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				if not is_game_running and is_start_pressed:
					launch_game()
				else:
					if $Bird.is_flying:
						$Bird.jump()
						check_if_bird_above_screen()
						$SfxWing.play()

func launch_game():
	is_game_running = true
	$Bird.is_flying = true
	$Bird.jump()
	$PipeTimer.start()
	$SfxWing.play()

func _process(delta):
	if is_game_running:
		background_scroll += BACKGROUND_SCROLL_SPEED
		if background_scroll >= screen_dimensions.x:
			background_scroll = 0
		$Ground.position.x = -background_scroll
		for pipe in active_pipes:
			pipe.position.x -= BACKGROUND_SCROLL_SPEED

func _on_pipe_timer_timeout():
	create_pipes()

func create_pipes():
	var pipe = pipe_scene.instantiate()
	pipe.position.x = screen_dimensions.x + PIPE_SPAWN_DELAY
	pipe.position.y = (screen_dimensions.y - ground_y_offset) / 2 + randi_range(-PIPE_POSITION_RANGE, PIPE_POSITION_RANGE)
	pipe.hit.connect(on_bird_hit)
	pipe.scored.connect(update_score)
	add_child(pipe)
	active_pipes.append(pipe)

func update_score():
	current_score += 1
	$ScoreLabel.text = "SCORE: " + str(current_score)
	final_score_display.text = "SCORE: " + str(current_score)
	$SfxPoint.play()

func check_if_bird_above_screen():
	if $Bird.position.y < 0:
		$Bird.is_falling = true
		end_game()
		play_audio($SfxGroudHit)

func end_game():
	if is_game_over:
		return
	$PipeTimer.stop()
	$GameOver.show()
	$ScoreLabel.hide()
	final_score_display.show()
	$Bird.is_flying = false
	$Bird.is_falling = false
	is_game_running = false
	is_game_over = true
	wait_for_sounds_then_play_game_over_sound()

func wait_for_sounds_then_play_game_over_sound():
	if is_game_running:
		return
	var active_audio_players = [
		$SfxWing,
		$SfxPoint,
		$SfxGroudHit,
		$SfxHit
	]
	for audio_player in active_audio_players:
		if audio_player.playing:
			await audio_player.finished
			if is_game_running:
				return
	play_game_over_sound()

func on_bird_hit():
	$Bird.is_falling = true
	play_audio($SfxHit)
	end_game()

func _on_ground_hit():
	$Bird.is_falling = false
	play_audio($SfxGroudHit)
	end_game()

func _on_game_over_restart():
	reset_game_over_sound()
	start_new_game()

func play_audio(audio_player: AudioStreamPlayer2D):
	if is_game_over_sound_playing:
		return
	audio_player.play()

func play_game_over_sound():
	is_game_over_sound_playing = true
	$SfxLoose.play()

func reset_game_over_sound():
	$SfxLoose.stop()
	is_game_over_sound_playing = false

func _on_play_button_pressed():
	$Beggining.hide()  # Скрыть главное меню, если оно есть
	start_new_game()  # Начать новую игру

func _on_beggining_start() -> void:
	is_start_pressed = true
	launch_game()
	$Beggining.hide()
	is_start_pressed = false

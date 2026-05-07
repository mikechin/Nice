## Tests for SwipeArea — direction-to-vector emission via SignalBus.
extends GdUnitTestSuite

const SwipeAreaScript = preload("res://scenes/components/swipe_area.gd")

var _area
var _captured_vectors: Array[Vector2]


func before_test() -> void:
	_area = auto_free(SwipeAreaScript.new())
	_area._is_enabled = true
	_captured_vectors = []
	SignalBus.swipe_detected.connect(_capture_vector)


func after_test() -> void:
	if SignalBus.swipe_detected.is_connected(_capture_vector):
		SignalBus.swipe_detected.disconnect(_capture_vector)


func _capture_vector(v: Vector2) -> void:
	_captured_vectors.append(v)


# Regression: SwipeArea used to emit Vector2.UP regardless of the actual swipe
# direction, breaking any consumer that subscribed to SignalBus.swipe_detected.

func test_left_swipe_emits_left_vector() -> void:
	_area._on_swipe_completed("left")
	assert_int(_captured_vectors.size()).is_equal(1)
	assert_that(_captured_vectors[0]).is_equal(Vector2.LEFT)


func test_right_swipe_emits_right_vector() -> void:
	_area._on_swipe_completed("right")
	assert_that(_captured_vectors[0]).is_equal(Vector2.RIGHT)


func test_up_swipe_emits_up_vector() -> void:
	_area._on_swipe_completed("up")
	assert_that(_captured_vectors[0]).is_equal(Vector2.UP)


func test_down_swipe_emits_down_vector() -> void:
	_area._on_swipe_completed("down")
	assert_that(_captured_vectors[0]).is_equal(Vector2.DOWN)

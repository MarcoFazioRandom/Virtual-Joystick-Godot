using Godot;
using System;

public partial class VirtualJoystickCS : Control
{
	[Export] public Color PressedColor = Colors.Gray;
	[Export(PropertyHint.Range, "0,200,1")] public float DeadzoneSize = 10;
	[Export(PropertyHint.Range, "0,500,1")] public float ClampzoneSize = 75;

	public enum JoystickMode { FIXED, DYNAMIC, FOLLOWING }
	[Export] public JoystickMode joystickMode = JoystickMode.FIXED;

	public enum VisibilityMode { ALWAYS, TOUCHSCREEN_ONLY, WHEN_TOUCHED }
	[Export] public VisibilityMode visibilityMode = VisibilityMode.ALWAYS;

	[Export] public bool UseInputActions = true;
	[Export] public string ActionLeft = "ui_left";
	[Export] public string ActionRight = "ui_right";
	[Export] public string ActionUp = "ui_up";
	[Export] public string ActionDown = "ui_down";

	public bool IsPressed = false;
	public Vector2 Output = Vector2.Zero;

	private int _touchIndex = -1;

	private Control _base;
	private Control _tip;

	private Vector2 _baseDefaultPosition;
	private Vector2 _tipDefaultPosition;
	private Color _defaultColor;

	public override void _Ready()
	{
		_base = GetNode<Control>("Base");
		_tip = _base.GetNode<Control>("Tip");

		_baseDefaultPosition = _base.Position;
		_tipDefaultPosition = _tip.Position;
		_defaultColor = _tip.Modulate;

		if ((bool)ProjectSettings.GetSetting("input_devices/pointing/emulate_mouse_from_touch"))
			GD.PrintErr("Set 'emulate_mouse_from_touch' to False");

		if (!(bool)ProjectSettings.GetSetting("input_devices/pointing/emulate_touch_from_mouse"))
			GD.PrintErr("Set 'emulate_touch_from_mouse' to True");

		if (!DisplayServer.IsTouchscreenAvailable() && visibilityMode == VisibilityMode.TOUCHSCREEN_ONLY)
			Hide();

		if (visibilityMode == VisibilityMode.WHEN_TOUCHED)
			Hide();
	}

	public override void _Input(InputEvent @event)
	{
		if (@event is InputEventScreenTouch touch)
		{
			if (touch.Pressed)
			{
				if (_IsPointInsideJoystickArea(touch.Position) && _touchIndex == -1)
				{
					if (joystickMode != JoystickMode.FIXED || _IsPointInsideBase(touch.Position))
					{
						if (joystickMode != JoystickMode.FIXED)
							_MoveBase(touch.Position);

						if (visibilityMode == VisibilityMode.WHEN_TOUCHED)
							Show();

						_touchIndex = touch.Index;
						_tip.Modulate = PressedColor;
						_UpdateJoystick(touch.Position);
						GetViewport().SetInputAsHandled();
					}
				}
			}
			else if (touch.Index == _touchIndex)
			{
				_Reset();
				if (visibilityMode == VisibilityMode.WHEN_TOUCHED)
					Hide();
				GetViewport().SetInputAsHandled();
			}
		}
		else if (@event is InputEventScreenDrag drag && drag.Index == _touchIndex)
		{
			_UpdateJoystick(drag.Position);
			GetViewport().SetInputAsHandled();
		}
	}

	private void _MoveBase(Vector2 newPos)
	{
		_base.GlobalPosition = newPos - _base.PivotOffset * GetGlobalTransformWithCanvas().Scale;
	}

	private void _MoveTip(Vector2 newPos)
	{
		_tip.GlobalPosition = newPos - _tip.PivotOffset * _base.GetGlobalTransformWithCanvas().Scale;
	}

	private bool _IsPointInsideJoystickArea(Vector2 point)
	{
		var scale = GetGlobalTransformWithCanvas().Scale;
		return point.X >= GlobalPosition.X && point.X <= GlobalPosition.X + (Size.X * scale.X)
			&& point.Y >= GlobalPosition.Y && point.Y <= GlobalPosition.Y + (Size.Y * scale.Y);
	}

	private Vector2 _GetBaseRadius()
	{
		return _base.Size * _base.GetGlobalTransformWithCanvas().Scale / 2f;
	}

	private bool _IsPointInsideBase(Vector2 point)
	{
		var radius = _GetBaseRadius();
		var center = _base.GlobalPosition + radius;
		var diff = point - center;
		return diff.LengthSquared() <= radius.X * radius.X;
	}

	private void _UpdateJoystick(Vector2 touchPos)
	{
		var radius = _GetBaseRadius();
		var center = _base.GlobalPosition + radius;
		var vector = touchPos - center;
		vector = vector.LimitLength(ClampzoneSize);

		if (joystickMode == JoystickMode.FOLLOWING && touchPos.DistanceTo(center) > ClampzoneSize)
			_MoveBase(touchPos - vector);

		_MoveTip(center + vector);

		if (vector.LengthSquared() > DeadzoneSize * DeadzoneSize)
		{
			IsPressed = true;
			Output = (vector - (vector.Normalized() * DeadzoneSize)) / (ClampzoneSize - DeadzoneSize);
		}
		else
		{
			IsPressed = false;
			Output = Vector2.Zero;
		}

		if (UseInputActions)
		{
			// Release first
			if (Output.X >= 0 && Input.IsActionPressed(ActionLeft)) Input.ActionRelease(ActionLeft);
			if (Output.X <= 0 && Input.IsActionPressed(ActionRight)) Input.ActionRelease(ActionRight);
			if (Output.Y >= 0 && Input.IsActionPressed(ActionUp)) Input.ActionRelease(ActionUp);
			if (Output.Y <= 0 && Input.IsActionPressed(ActionDown)) Input.ActionRelease(ActionDown);

			// Then press
			if (Output.X < 0) Input.ActionPress(ActionLeft, -Output.X);
			if (Output.X > 0) Input.ActionPress(ActionRight, Output.X);
			if (Output.Y < 0) Input.ActionPress(ActionUp, -Output.Y);
			if (Output.Y > 0) Input.ActionPress(ActionDown, Output.Y);
		}
	}

	private void _Reset()
	{
		IsPressed = false;
		Output = Vector2.Zero;
		_touchIndex = -1;
		_tip.Modulate = _defaultColor;
		_base.Position = _baseDefaultPosition;
		_tip.Position = _tipDefaultPosition;

		if (UseInputActions)
		{
			foreach (string action in new[] { ActionLeft, ActionRight, ActionDown, ActionUp })
			{
				if (Input.IsActionPressed(action))
					Input.ActionRelease(action);
			}
		}
	}

}

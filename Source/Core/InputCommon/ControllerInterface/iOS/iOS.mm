// Copyright 2019 Dolphin Emulator Project
// Licensed under GPLv2+
// Refer to the license.txt file included.

#include "InputCommon/ControllerInterface/iOS/ControllerScanner.h"
#include "InputCommon/ControllerInterface/iOS/iOS.h"
#include "InputCommon/ControllerInterface/iOS/Motor.h"
#include "InputCommon/ControllerInterface/ControllerInterface.h"
#include "InputCommon/ControllerInterface/Touch/Touchscreen.h"

namespace ciface::iOS
{
static ControllerScanner* s_controller_scanner;

void Init()
{
  s_controller_scanner = [[ControllerScanner alloc] init];
}

void DeInit()
{
  s_controller_scanner = nil;
}

void PopulateDevices()
{
  // Begin scanning for controllers
  [s_controller_scanner BeginControllerScan];

  // Add every connected controller
  for (GCController* controller in [GCController controllers])
  {
    g_controller_interface.AddDevice(std::make_shared<Controller>(controller));
  }

  // Add one Touchscreen device
  for (int i = 0; i < 8; i++)
  {
    g_controller_interface.AddDevice(std::make_shared<ciface::Touch::Touchscreen>(i, true, true));
  }
}

Controller::Controller(GCController* controller) : m_controller(controller)
{
  if (controller.extendedGamepad != nil)
  {
    GCExtendedGamepad* gamepad = controller.extendedGamepad;
    AddInput(new Button(gamepad.buttonA, "Button A"));
    AddInput(new Button(gamepad.buttonB, "Button B"));
    AddInput(new Button(gamepad.buttonX, "Button X"));
    AddInput(new Button(gamepad.buttonY, "Button Y"));
    AddInput(new Button(gamepad.dpad.up, "D-Pad Up"));
    AddInput(new Button(gamepad.dpad.down, "D-Pad Down"));
    AddInput(new Button(gamepad.dpad.left, "D-Pad Left"));
    AddInput(new Button(gamepad.dpad.right, "D-Pad Right"));
    AddInput(new PressureSensitiveButton(gamepad.leftShoulder, "L Shoulder"));
    AddInput(new PressureSensitiveButton(gamepad.rightShoulder, "R Shoulder"));
    AddInput(new PressureSensitiveButton(gamepad.leftTrigger, "L Trigger"));
    AddInput(new PressureSensitiveButton(gamepad.rightTrigger, "R Trigger"));
    AddInput(new Axis(gamepad.leftThumbstick.xAxis, 1.0f, "L Stick X+"));
    AddInput(new Axis(gamepad.leftThumbstick.xAxis, -1.0f, "L Stick X-"));
    AddInput(new Axis(gamepad.leftThumbstick.yAxis, 1.0f, "L Stick Y+"));
    AddInput(new Axis(gamepad.leftThumbstick.yAxis, -1.0f, "L Stick Y-"));
    AddInput(new Axis(gamepad.rightThumbstick.xAxis, 1.0f, "R Stick X+"));
    AddInput(new Axis(gamepad.rightThumbstick.xAxis, -1.0f, "R Stick X-"));
    AddInput(new Axis(gamepad.rightThumbstick.yAxis, 1.0f, "R Stick Y+"));
    AddInput(new Axis(gamepad.rightThumbstick.yAxis, -1.0f, "R Stick Y-"));

    // Optionals and buttons only on newer iOS versions
    if (@available(iOS 14, *))
    {
      if ([gamepad isKindOfClass:[GCDualShockGamepad class]])
      {
        GCDualShockGamepad* ds_gamepad = (GCDualShockGamepad*)gamepad;
        AddInput(new Button(ds_gamepad.touchpadButton, "Touchpad"));
        AddInput(new Axis(ds_gamepad.touchpadPrimary.xAxis, 1.0f, "Touchpad X+"));
        AddInput(new Axis(ds_gamepad.touchpadPrimary.xAxis, -1.0f, "Touchpad X-"));
        AddInput(new Axis(ds_gamepad.touchpadPrimary.yAxis, 1.0f, "Touchpad Y+"));
        AddInput(new Axis(ds_gamepad.touchpadPrimary.yAxis, -1.0f, "Touchpad Y-"));

        // TODO: WTF is touchpadSecondary?
      }
      else if ([gamepad isKindOfClass:[GCXboxGamepad class]])
      {
        GCXboxGamepad* xbox_gamepad = (GCXboxGamepad*)gamepad;
        AddInput(new Button(xbox_gamepad.paddleButton1, "Paddle 1"));
        AddInput(new Button(xbox_gamepad.paddleButton2, "Paddle 2"));
        AddInput(new Button(xbox_gamepad.paddleButton3, "Paddle 3"));
        AddInput(new Button(xbox_gamepad.paddleButton4, "Paddle 4"));
      }
    }

    if (@available(iOS 13, *))
    {
      AddInput(new Button(gamepad.buttonMenu, "Menu"));

      if (gamepad.buttonOptions != nil)
      {
        AddInput(new Button(gamepad.buttonOptions, "Options"));
      }
    }

    if (@available(iOS 12.1, *))
    {
      if (gamepad.leftThumbstickButton != nil)
      {
        AddInput(new Button(gamepad.leftThumbstickButton, "L Stick"));
      }

      if (gamepad.rightThumbstickButton != nil)
      {
        AddInput(new Button(gamepad.rightThumbstickButton, "R Stick"));
      }
    }
  }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  else if (controller.gamepad != nil)
  {
    // Deprecated in iOS 10, but needed for some older controllers
    GCGamepad* gamepad = controller.gamepad;
    AddInput(new Button(gamepad.buttonA, "Button A"));
    AddInput(new Button(gamepad.buttonB, "Button B"));
    AddInput(new Button(gamepad.buttonX, "Button X"));
    AddInput(new Button(gamepad.buttonY, "Button Y"));
    AddInput(new Button(gamepad.dpad.up, "D-Pad Up"));
    AddInput(new Button(gamepad.dpad.down, "D-Pad Down"));
    AddInput(new Button(gamepad.dpad.left, "D-Pad Left"));
    AddInput(new Button(gamepad.dpad.right, "D-Pad Right"));
    AddInput(new PressureSensitiveButton(gamepad.leftShoulder, "L Shoulder"));
    AddInput(new PressureSensitiveButton(gamepad.rightShoulder, "R Shoulder"));
  }
#pragma clang diagnostic pop
  else if (controller.microGamepad != nil)  // Siri Remote
  {
    GCMicroGamepad* gamepad = controller.microGamepad;
    AddInput(new Button(gamepad.dpad.up, "D-Pad Up"));
    AddInput(new Button(gamepad.dpad.down, "D-Pad Down"));
    AddInput(new Button(gamepad.dpad.left, "D-Pad Left"));
    AddInput(new Button(gamepad.dpad.right, "D-Pad Right"));
    AddInput(new Button(gamepad.buttonA, "Button A"));
    AddInput(new Button(gamepad.buttonX, "Button X"));

    if (@available(iOS 13, *))
    {
      AddInput(new Button(gamepad.buttonMenu, "Menu"));
    }
  }

  if (controller.motion != nil)
  {
    GCMotion* motion = controller.motion;

    if (@available(iOS 14.0, *))
    {
      // The DualShock 4 requires manual sensor activation
      if (motion.sensorsRequireManualActivation)
      {
        motion.sensorsActive = true;
      }
    }

    bool separate_gravity = true;

    if (@available(iOS 14.0, *))
    {
      // Query GCMotion to see if the controller doeson't separate gravity
      // and acceleration, like the DualShock 4
      separate_gravity = motion.hasGravityAndUserAcceleration;
    } 
    
    AddInput(new AccelerometerAxis(motion, X, -1.0, separate_gravity, "Accel Left"));
    AddInput(new AccelerometerAxis(motion, X, 1.0, separate_gravity, "Accel Right"));
    AddInput(new AccelerometerAxis(motion, Y, 1.0, separate_gravity, "Accel Forward"));
    AddInput(new AccelerometerAxis(motion, Y, -1.0, separate_gravity, "Accel Back"));
    AddInput(new AccelerometerAxis(motion, Z, 1.0, separate_gravity, "Accel Up"));
    AddInput(new AccelerometerAxis(motion, Z, -1.0, separate_gravity, "Accel Down"));

    if (@available(iOS 14.0, *))
    {
      m_supports_gyroscope = motion.hasRotationRate;
    }
    else
    {
      m_supports_gyroscope = motion.hasAttitudeAndRotationRate;
    }

    if (m_supports_gyroscope)
    {
      AddInput(new GyroscopeAxis(motion, X, 1.0, "Gyro Pitch Up"));
      AddInput(new GyroscopeAxis(motion, X, -1.0, "Gyro Pitch Down"));
      AddInput(new GyroscopeAxis(motion, Y, -1.0, "Gyro Roll Left"));
      AddInput(new GyroscopeAxis(motion, Y, 1.0, "Gyro Roll Right"));
      AddInput(new GyroscopeAxis(motion, Z, -1.0, "Gyro Yaw Left"));
      AddInput(new GyroscopeAxis(motion, Z, 1.0, "Gyro Yaw Right"));
    }

    m_supports_accelerometer = true;
  }
  else
  {
    m_supports_accelerometer = false;
  }

  if (@available(iOS 14.0, *))
  {
    GCDeviceHaptics* haptics = controller.haptics;
    if (haptics != nil)
    {
      AddOutput(new Motor("Rumble", [haptics createEngineWithLocality:GCHapticsLocalityDefault]));
    }
  }
}

std::string Controller::GetName() const
{
  NSString* vendor_name = m_controller.vendorName;
  if (m_controller.vendorName != nil)
  {
    return std::string([m_controller.vendorName UTF8String]);
  }
  else
  {
    return "Unknown Controller";
  }
}

std::string Controller::GetSource() const
{
  return "MFi";
}

bool Controller::SupportsAccelerometer() const
{
  return m_supports_accelerometer;
}

bool Controller::SupportsGyroscope() const
{
  return m_supports_gyroscope;
}

bool Controller::IsSameController(GCController* controller) const
{
  return m_controller == controller;
}

std::string Controller::Button::GetName() const
{
  return m_name;
}

ControlState Controller::Button::GetState() const
{
  return m_input.isPressed;
}

std::string Controller::PressureSensitiveButton::GetName() const
{
  return m_name;
}

ControlState Controller::PressureSensitiveButton::GetState() const
{
  return m_input.value;
}

std::string Controller::Axis::GetName() const
{
  return m_name;
}

ControlState Controller::Axis::GetState() const
{
  return m_input.value * m_multiplier;
}

Controller::AccelerometerAxis::AccelerometerAxis(GCMotion* motion, MotionPlane plane,
                                                const double multiplier, bool separate_gravity,
                                                const std::string name)
    : m_motion(motion), m_plane(plane), m_separate_gravity(separate_gravity), m_name(name) 
{
  if (plane == X || plane == Y)
  {
    m_multiplier = -1.0;
  }
  else  // Z
  {
    m_multiplier = 1.0;
  }

  m_multiplier *= multiplier;
}

std::string Controller::AccelerometerAxis::GetName() const
{
  return m_name;
}

ControlState Controller::AccelerometerAxis::GetState() const
{
  GCAcceleration acceleration;
  double full_multiplier = m_multiplier;

  if (m_separate_gravity)
  {
    full_multiplier *= -9.81;
    acceleration = m_motion.userAcceleration;
  }
  else
  {
    acceleration = m_motion.acceleration;
  }

  switch (m_plane)
  {
  case X:
    return acceleration.x * full_multiplier;
  case Y:
    return acceleration.y * full_multiplier;
  case Z:
    return acceleration.z * full_multiplier;
  }
}

Controller::GyroscopeAxis::GyroscopeAxis(GCMotion* motion, MotionPlane plane,
                                         const double multiplier, const std::string name)
    : m_motion(motion), m_plane(plane), m_name(name)
{
  if (plane == X || plane == Y)
  {
    m_multiplier = -1.0;
  }
  else  // Z
  {
    m_multiplier = 1.0;
  }

  m_multiplier *= multiplier;
}

std::string Controller::GyroscopeAxis::GetName() const
{
  return m_name;
}

ControlState Controller::GyroscopeAxis::GetState() const
{
  switch (m_plane)
  {
  case X:
    return m_motion.rotationRate.x * m_multiplier;
  case Y:
    return m_motion.rotationRate.y * m_multiplier;
  case Z:
    return m_motion.rotationRate.z * m_multiplier;
  }
}

}  // namespace ciface::iOS

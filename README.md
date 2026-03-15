Disclaimer -

I tested this code in my own projects, but this code has been with heavy assistance from Claude Code. If you see a problem - submit a ticket!

# rn-selectable-text

A React Native library for custom text selection menus, redesigned from the ground up for React Native 0.81.1 with full support for the new architecture (Fabric).

The `SelectableTextView` component wraps your text content and provides custom menu options that appear when users select text. It supports nested text styling and cross-platform event handling.

## Features

- Cross-platform support (iOS & Android)
- Support for nested text with different styles
- Custom menu options with callback handling

## Installation

```sh
yarn add @thiagobueno/rn-selectable-text
```

For iOS, run pod install:
```sh
cd ios && pod install
```

## Usage

### Basic Example

```tsx
import React, { useState } from 'react';
import { View, Text, Alert } from 'react-native';
import { SelectableTextView } from '@thiagobueno/rn-selectable-text';

export default function App() {

  const handleSelection = (event) => {
    const { chosenOption, highlightedText } = event;
    Alert.alert(
      'Selection Event',
      `Option: ${chosenOption}\nSelected Text: ${highlightedText}`
    );
  };

  return (
    <View>

      <SelectableTextView
        menuOptions={['look up', 'copy', 'share']}
        onSelection={handleSelection}
        style={{ margin: 20 }}
      >
        <Text>This is simple selectable text</Text>
      </SelectableTextView>
    </View>
  );
}
```

### Advanced Example with Nested Text Styling

```jsx
<SelectableTextView
  menuOptions={['Action 1', 'Action 2', 'Custom Action']}
  onSelection={handleSelection}
  style={{ marginHorizontal: 20 }}
>
  <Text style={{ color: 'black', fontSize: 16 }}>
    This text is black{' '}
    <Text style={{ textDecorationLine: 'underline', color: 'red' }}>
      this part is underlined and red
    </Text>{' '}
    and this is black again. All of it is selectable with custom menu options!
  </Text>
</SelectableTextView>
```

## API Reference

### SelectableTextView Props

| Prop          | Type                              | Required | Description                                 |
| ------------- | --------------------------------- | -------- | ------------------------------------------- |
| `children`    | `React.ReactNode`                 | Yes      | Text components to make selectable          |
| `menuOptions` | `string[]`                        | Yes      | Array of menu option strings                |
| `onSelection` | `(event: SelectionEvent) => void` | No       | Callback fired when menu option is selected |
| `style`       | `ViewStyle`                       | No       | Style object for the container              |

### SelectionEvent

The `onSelection` callback receives an event object with:

```typescript
interface SelectionEvent {
  chosenOption: string;    // The menu option that was selected
  highlightedText: string; // The text that was highlighted by the user
}
```

## Requirements

- React Native 0.81.1+
- iOS 11.0+
- Android API level 21+
- React Native's new architecture (Fabric) enabled

## Platform Differences

The library handles platform differences internally:
- **iOS**: Uses direct event handlers for optimal performance
- **Android**: Uses DeviceEventEmitter for reliable event delivery

Both platforms provide the same API and functionality.

## License

MIT
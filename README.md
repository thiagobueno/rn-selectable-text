# rn-selectable-text

[![npm version](https://badge.fury.io/js/@thiagobueno%2Frn-selectable-text.svg)](https://badge.fury.io/js/@thiagobueno%2Frn-selectable-text)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A highly stable, Fabric-compatible React Native library for custom text selection menus. Redesigned from the ground up for **React Native 0.81+** and the **New Architecture**.

The `SelectableTextView` component wraps your text content and provides custom native menu options that appear when users select text. It elegantly handles nested text styling, cross-platform event handling, and modern OS requirements.

## 🚀 Why use this package? (Key Fixes)

This library was heavily refactored to solve critical issues present in older selectable text libraries:
- **True Fabric Support:** Fully compatible with React Native's New Architecture (C++ Codegen).
- **iOS 16+ Stability:** Replaces the deprecated and crash-prone `UIMenuController` with the modern `UIEditMenuInteraction` API.
- **Bypasses iOS Menu Suppression:** Safely mocks copy selectors to prevent the modern iOS engine from suppressing your custom menu.
- **View Recycling Poisoning Fix:** Solves the severe Fabric bug where sibling UI elements (like icons and buttons) would randomly disappear from the screen due to improper native state cleanups.

## 📦 Installation

```sh
yarn add @thiagobueno/rn-selectable-text
# or
npm install @thiagobueno/rn-selectable-text
```

For iOS, run pod install:
```sh
cd ios && pod install
```

## 🛠 Usage

### Basic Example

```tsx
import React from 'react';
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
        <View style={{ flex: 1, justifyContent: 'center', padding: 20 }}>
            <SelectableTextView
                menuOptions={['Save', 'Share', 'Copy']}
                onSelection={handleSelection}
            >
                <Text style={{ fontSize: 18, color: '#333' }}>
                    Highlight this text to see the custom native menu!
                </Text>
            </SelectableTextView>
        </View>
    );
}
```

### Invisible Custom Mode (ActionSheet & Bottom Sheet Integration)

If you want to use modern UIs like Apple's native `ActionSheetIOS` or a custom React Native Bottom Sheet, you can bypass the default horizontal bubble menu entirely. 

By passing an **empty array (`[]`)** to `menuOptions`, the library enters **Invisible Mode**. It completely suppresses the native iOS/Android bubble menus while still tracking text selection in real-time and emitting the `CUSTOM_MODE` event.

```tsx
import React, { useState } from 'react';
import { View, Text, Platform, ActionSheetIOS, Modal, Button, StyleSheet } from 'react-native';
import { SelectableTextView } from '@thiagobueno/rn-selectable-text';

export default function InvisibleModeApp() {
    const [androidMenuVisible, setAndroidMenuVisible] = useState(false);
    const [selectedText, setSelectedText] = useState('');

    const handleSelection = ({ chosenOption, highlightedText }) => {
        // 1. Hide menus if the user taps away and clears the selection
        if (highlightedText.length === 0) {
            setAndroidMenuVisible(false);
            return;
        }

        // 2. Invisible Mode triggers the "CUSTOM_MODE" option
        if (chosenOption === 'CUSTOM_MODE') {
            setSelectedText(highlightedText);

            if (Platform.OS === 'ios') {
                // Open Apple's Native Bottom Sheet
                ActionSheetIOS.showActionSheetWithOptions(
                    {
                        title: 'Text Actions',
                        options: ['Cancel', 'Share to WhatsApp', 'Save'],
                        cancelButtonIndex: 0,
                    },
                    (buttonIndex) => {
                        if (buttonIndex === 1) console.log('WhatsApp:', highlightedText);
                        if (buttonIndex === 2) console.log('Save:', highlightedText);
                    }
                );
            } else {
                // Open Custom React Native Bottom Sheet for Android
                setAndroidMenuVisible(true);
            }
        }
    };

    return (
        <View style={{ flex: 1, padding: 20, justifyContent: 'center' }}>
            <SelectableTextView
                menuOptions={[]} // The empty array is the magic key for Invisible Mode
                onSelection={handleSelection}
            >
                <Text style={{ fontSize: 18, color: '#333' }}>
                    Select this text. The native bubble menu is suppressed, allowing you
                    to render a beautiful Action Sheet or custom Modal instead!
                </Text>
            </SelectableTextView>

            {Platform.OS === 'android' && (
                <Modal visible={androidMenuVisible} transparent animationType="slide">
                    <View style={styles.modalOverlay}>
                        <View style={styles.bottomSheet}>
                            <Text style={{ marginBottom: 15 }}>Selected: {selectedText}</Text>
                            <Button title="Save" onPress={() => setAndroidMenuVisible(false)} />
                            <Button title="Close" color="red" onPress={() => setAndroidMenuVisible(false)} />
                        </View>
                    </View>
                </Modal>
            )}
        </View>
    );
}

const styles = StyleSheet.create({
    modalOverlay: {
        flex: 1,
        justifyContent: 'flex-end',
        backgroundColor: 'rgba(0,0,0,0.5)'
    },
    bottomSheet: {
        backgroundColor: 'white',
        padding: 20,
        borderTopLeftRadius: 20,
        borderTopRightRadius: 20
    }
});
```

### Advanced Example (Nested Text & Index Mapping)

When dealing with internationalization (i18n) or dynamic menus, it's highly recommended to map your selections by index rather than relying on the translated string.

```jsx
import React from 'react';
import { View, Text } from 'react-native';
import { SelectableTextView } from '@thiagobueno/rn-selectable-text';

const MENU_OPTIONS = ['Save Note', 'Edit Text', 'Highlight Content'];

export default function AdvancedApp() {

    const handleSelection = ({ chosenOption, highlightedText }) => {
        const actionIndex = MENU_OPTIONS.indexOf(chosenOption);

        switch (actionIndex) {
            case 0:
                console.log('Action: Save Note - Text:', highlightedText);
                break;
            case 1:
                console.log('Action: Edit Text - Text:', highlightedText);
                break;
            case 2:
                console.log('Action: Highlight Content - Text:', highlightedText);
                break;
        }
    };

    return (
        <View style={{ padding: 20 }}>
            <SelectableTextView
                menuOptions={MENU_OPTIONS}
                onSelection={handleSelection}
            >
                <Text style={{ color: 'black', fontSize: 16 }}>
                    This text is black, but{' '}
                    <Text style={{ fontWeight: 'bold', color: 'blue' }}>
                        this part is bold and blue
                    </Text>{' '}
                    and this is black again. The entire block is selectable!
                </Text>
            </SelectableTextView>
        </View>
    );
}
```

## 📖 API Reference

### SelectableTextView Props

| Prop          | Type                              | Required | Description                                 |
| ------------- | --------------------------------- | -------- | ------------------------------------------- |
| `children`    | `React.ReactNode`                 | Yes      | Text components to make selectable          |
| `menuOptions` | `string[]`                        | Yes      | Array of custom menu option strings         |
| `onSelection` | `(event: SelectionEvent) => void` | No       | Callback fired when a menu option is tapped |
| `style`       | `ViewStyle`                       | No       | Style object for the native container       |

### SelectionEvent

The `onSelection` callback receives an event object with:

```typescript
interface SelectionEvent {
    chosenOption: string;    // The exact string of the menu option selected
    highlightedText: string; // The specific text highlighted by the user
}
```

## ⚙️ Requirements

- React Native 0.81.1+
- iOS 15.1+ (Optimized for modern APIs)
- Android API level 21+
- React Native's New Architecture (Fabric) enabled

## 🔄 Platform Differences

The library handles platform differences internally, providing the same API and functionality for both:
- **iOS**: Uses direct event handlers and the modern `UIEditMenuInteraction` API for optimal performance.
- **Android**: Uses `DeviceEventEmitter` for reliable event delivery and bridges native selection to the JS thread.

## ⚖️ License
MIT
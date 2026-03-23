package com.selectabletext

import android.content.Context
import android.util.AttributeSet
import android.view.ActionMode
import android.view.Menu
import android.view.MenuItem
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.TextView
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.modules.core.DeviceEventManagerModule

class SelectableTextView : FrameLayout {
  private var menuOptions: Array<String> = emptyArray()
  private var textView: TextView? = null
  
  // Holds the reference to the native Android ActionMode (the text selection menu)
  private var currentActionMode: ActionMode? = null
  
  constructor(context: Context?) : super(context!!)
  constructor(context: Context?, attrs: AttributeSet?) : super(context!!, attrs)
  constructor(context: Context?, attrs: AttributeSet?, defStyleAttr: Int) : super(
    context!!,
    attrs,
    defStyleAttr
  )
  
  fun setMenuOptions(options: Array<String>) {
    this.menuOptions = options
    setupTextView()
  }
  
  private fun setupTextView() {
    // Find the first TextView child
    for (i in 0 until childCount) {
      val child = getChildAt(i)
      if (child is TextView) {
        textView = child
        setupSelectionCallback(child)
        break
      }
    }
  }
  
  private fun setupSelectionCallback(textView: TextView) {
    textView.setTextIsSelectable(true)
    textView.customSelectionActionModeCallback = object : ActionMode.Callback {
      override fun onCreateActionMode(mode: ActionMode?, menu: Menu?): Boolean {
        // Save the reference of the native Android bar as soon as it is created
        currentActionMode = mode
        return true
      }
      
      override fun onPrepareActionMode(mode: ActionMode?, menu: Menu?): Boolean {
        menu?.clear()
        
        // ====================================================================
        // CUSTOM INVISIBLE MODE: Suppress native menu if array is empty
        // ====================================================================
        if (menuOptions.isEmpty()) {
            // Trick to hide the native action bar: assign a 1x1 pixel empty view
            val view = View(context)
            view.layoutParams = ViewGroup.LayoutParams(1, 1)
            mode?.customView = view
            
            val selectionStart = textView.selectionStart
            val selectionEnd = textView.selectionEnd
            if (selectionEnd > selectionStart) {
                val selectedText = textView.text.toString().substring(selectionStart, selectionEnd)
                onSelectionEvent("CUSTOM_MODE", selectedText)
            }
            return true
        }

        // Standard behavior: populate native menu
        menuOptions.forEachIndexed { index, option ->
          menu?.add(0, index, 0, option)
        }
        return true
      }
      
      override fun onActionItemClicked(mode: ActionMode?, item: MenuItem?): Boolean {
        val selectionStart = textView.selectionStart
        val selectionEnd = textView.selectionEnd
        val selectedText = textView.text.toString().substring(selectionStart, selectionEnd)
        val chosenOption = menuOptions[item?.itemId ?: 0]
        
        // Send event to React Native
        onSelectionEvent(chosenOption, selectedText)
        
        mode?.finish()
        return true
      }
      
      override fun onDestroyActionMode(mode: ActionMode?) {
        // Clear the reference when the user closes the menu by tapping outside
        currentActionMode = null
      }
    }
  }
  
  private fun onSelectionEvent(chosenOption: String, highlightedText: String) {
    val reactContext = context as ReactContext
    val params = Arguments.createMap().apply {
      putInt("viewTag", id)
      putString("chosenOption", chosenOption)
      putString("highlightedText", highlightedText)
    }
    
    reactContext
      .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
      .emit("SelectableTextSelection", params)
  }
  
  override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
    super.onLayout(changed, left, top, right, bottom)
    if (changed && textView == null) {
      setupTextView()
    }
  }

  // ====================================================================
  // SAFETY FIX (Preventing the disappearing views bug)
  // ====================================================================
  override fun onDetachedFromWindow() {
    super.onDetachedFromWindow()
    // If React Native decides to remove this View from the screen (scroll or navigation)
    // and the native bar is still open, we force it to close.
    // This frees up memory and releases the Android UI Thread.
    currentActionMode?.finish()
    currentActionMode = null
  }
}
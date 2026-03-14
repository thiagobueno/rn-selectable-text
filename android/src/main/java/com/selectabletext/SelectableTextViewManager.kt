package com.selectabletext

import com.facebook.react.bridge.ReadableArray
import com.facebook.react.common.MapBuilder
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.ViewGroupManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.SelectableTextViewManagerInterface
import com.facebook.react.viewmanagers.SelectableTextViewManagerDelegate

@ReactModule(name = SelectableTextViewManager.NAME)
class SelectableTextViewManager : ViewGroupManager<SelectableTextView>(),
  SelectableTextViewManagerInterface<SelectableTextView> {
  private val mDelegate: ViewManagerDelegate<SelectableTextView>

  init {
    mDelegate = SelectableTextViewManagerDelegate(this)
  }

  override fun getDelegate(): ViewManagerDelegate<SelectableTextView>? {
    return mDelegate
  }

  override fun getName(): String {
    return NAME
  }

  public override fun createViewInstance(context: ThemedReactContext): SelectableTextView {
    return SelectableTextView(context)
  }

  @ReactProp(name = "menuOptions")
  override fun setMenuOptions(view: SelectableTextView, menuOptions: ReadableArray?) {
    if (menuOptions != null) {
      val options = Array(menuOptions.size()) { i ->
        menuOptions.getString(i) ?: ""
      }
      view.setMenuOptions(options)
    }
  }

  override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any>? {
    return MapBuilder.builder<String, Any>()
      .put("topSelection", MapBuilder.of("registrationName", "onSelection"))
      .build()
  }

  companion object {
    const val NAME = "SelectableTextView"
  }
}

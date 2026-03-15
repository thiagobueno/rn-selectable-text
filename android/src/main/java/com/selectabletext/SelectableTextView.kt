package com.selectabletext

import android.content.Context
import android.util.AttributeSet
import android.view.ActionMode
import android.view.Menu
import android.view.MenuItem
import android.widget.FrameLayout
import android.widget.TextView
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.modules.core.DeviceEventManagerModule

class SelectableTextView : FrameLayout {
  private var menuOptions: Array<String> = emptyArray()
  private var textView: TextView? = null
  
  // A MÁGICA: Variável para segurar a referência do menu nativo do Android
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
        // Salva a referência da barra nativa do Android assim que ela nasce
        currentActionMode = mode
        return true
      }
      
      override fun onPrepareActionMode(mode: ActionMode?, menu: Menu?): Boolean {
        menu?.clear()
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
        // Limpa a referência quando o próprio usuário fecha o menu tocando fora
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
  // A CIRURGIA DE SEGURANÇA (Prevenção do Bug das Views que Somem)
  // ====================================================================
  override fun onDetachedFromWindow() {
    super.onDetachedFromWindow()
    // Se o React Native decidir remover essa View da tela (scroll ou navegação)
    // e a barra nativa ainda estiver aberta, nós a fechamos à força.
    // Isso devolve a memória e libera a UI Thread do Android.
    currentActionMode?.finish()
    currentActionMode = null
  }
}
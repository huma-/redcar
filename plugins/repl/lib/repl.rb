require 'java'
require 'repl/internal_mirror'

require File.dirname(__FILE__) + "/../vendor/clojure.jar"

include_class 'clojure.lang.Var'
include_class 'clojure.lang.RT'

module Redcar
  class REPL
    def self.sensitivities
      [
        Sensitivity.new(:open_repl_tab, Redcar.app, false, [:tab_focussed]) do |tab|
          tab and 
          tab.is_a?(EditTab) and 
          tab.edit_view.document.mirror.is_a?(REPL::InternalMirror)
        end
      ]
    end

    def self.keymaps
      osx = Keymap.build("main", :osx) do
        link "Cmd+Shift+M", REPL::OpenInternalREPL
        link "Cmd+M",       REPL::CommitREPL
      end
      
      linwin = Keymap.build("main", [:linux, :windows]) do
        link "Ctrl+Shift+M", REPL::OpenInternalREPL
        link "Ctrl+M",       REPL::CommitREPL
      end
      
      [linwin, osx]
    end
    
    def self.menus
      Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "REPL" do
            item "Open Ruby REPL",    REPL::OpenInternalREPL
            item "Open Clojure REPL", REPL::OpenClojureREPL
            item "Execute", REPL::CommitREPL
          end
        end
      end
    end
    
    class OpenREPL < Command
      
      def open_repl eval_proc
        tab = win.new_tab(Redcar::EditTab)
        edit_view = tab.edit_view
        edit_view.document.mirror = REPL::InternalMirror.new eval_proc
        edit_view.cursor_offset = edit_view.document.length
        tab.focus
      end
    end
    
    class OpenInternalREPL < OpenREPL
      def execute
	      open_repl Proc.new { |expr,binding| eval(expr, binding) }
      end
    end
    
    class OpenClojureREPL < OpenREPL
      
      def execute
	
        eval_proc = Proc.new do |expr, binding|
	        load_string = RT.var("clojure.core", "load-string")
	        load_string.invoke(expr)      
	      end
	
	      open_repl eval_proc
      end
    end
    
    class ReplCommand < Command
      sensitize :open_repl_tab
    end
    
    class CommitREPL < ReplCommand
      
      def execute
        edit_view = win.focussed_notebook.focussed_tab.edit_view
        edit_view.document.save!
        edit_view.cursor_offset = edit_view.document.length
        edit_view.scroll_to_line(edit_view.document.line_count)
      end
    end
  end
end



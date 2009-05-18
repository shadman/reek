require 'rubygems'
require 'sexp_processor'
require 'reek/block_context'
require 'reek/class_context'
require 'reek/module_context'
require 'reek/stop_context'
require 'reek/if_context'
require 'reek/method_context'
require 'reek/singleton_method_context'
require 'reek/yield_call_context'

module Reek

  class CodeParser < SexpProcessor

    # Creates a new Ruby code checker. Any smells discovered by
    # +check_source+ or +check_object+ will be stored in +report+.
    def initialize(report, smells, ctx = StopContext.new)
      super()
      @report = report
      @smells = smells
      @element = ctx
      @unsupported -= [:cfunc]
      @default_method = :process_default
      @require_empty = @warn_on_default = false
    end

    def process_default(exp)
      exp[0..-1].each { |sub| process(sub) if Array === sub }
      s(exp)
    end

    def process_module(exp)
      push(ModuleContext.create(@element, exp)) do
        process_default(exp)
        check_smells(:module)
      end
      s(exp)
    end

    def process_class(exp)
      push(ClassContext.create(@element, exp)) do
        process_default(exp) unless @element.is_struct?
        check_smells(:class)
      end
      s(exp)
    end

    def process_defn(exp)
      handle_context(MethodContext, :defn, exp)
    end

    def process_defs(exp)
      handle_context(SingletonMethodContext, :defs, exp)
    end

    def process_args(exp)
      exp[1..-1].each {|sym| @element.record_parameter(sym) }
      s(exp)
    end

    def process_attrset(exp)
      @element.record_depends_on_self if /^@/ === exp[1].to_s
      s(exp)
    end

    def process_lit(exp)
      val = exp[1]
      @element.record_depends_on_self if val == :self
      s(exp)
    end

    def process_iter(exp)
      process(exp[1])
      handle_context(BlockContext, :iter, exp[2..-1])
    end
    
    def process_dasgn_curr(exp)
      @element.record_parameter(exp[1])
      process_default(exp)
    end

    def process_block(exp)
      @element.count_statements(CodeParser.count_statements(exp))
      process_default(exp)
    end

    def process_yield(exp)
      handle_context(YieldCallContext, :yield, exp)
    end

    def process_call(exp)
      @element.record_call_to(exp)
      process_default(exp)
    end

    def process_fcall(exp)
      @element.record_use_of_self
      process_default(exp)
    end

    def process_cfunc(exp)
      @element.record_depends_on_self
      s(exp)
    end

    def process_vcall(exp)
      @element.record_use_of_self
      s(exp)
    end

    def process_attrasgn(exp)
      process_call(exp)
    end

    def process_op_asgn1(exp)
      process_call(exp)
    end

    def process_if(exp)
      handle_context(IfContext, :if, exp)
    end

    def process_ivar(exp)
      process_iasgn(exp)
    end

    def process_lasgn(exp)
      @element.record_local_variable(exp[1])
      process(exp[2])
      s(exp)
    end

    def process_iasgn(exp)
      @element.record_instance_variable(exp[1])
      @element.record_depends_on_self
      process_default(exp)
    end

    def process_self(exp)
      @element.record_depends_on_self
      s(exp)
    end

    def self.count_statements(exp)
      stmts = exp[1..-1]
      ignore = 0
      ignore = 1 if is_expr?(stmts[0], :args)
      ignore += 1 if stmts[1] == s(:nil)
      stmts.length - ignore
    end

  private

    def self.is_expr?(exp, type)
      Array === exp and exp[0] == type
    end

    def self.is_global_variable?(exp)
      is_expr?(exp, :gvar)
    end

    def handle_context(klass, type, exp)
      push(klass.new(@element, exp)) do
        process_default(exp)
        check_smells(type)
      end
      s(exp)
    end

    def check_smells(type)
      @smells[type].each {|smell| smell.examine(@element, @report) }
    end

    def push(context)
      orig = @element
      @element = context
      yield
      @element = orig
    end
    
    def pop(exp)
      @element = @element.outer
      s(exp)
    end
  end
end

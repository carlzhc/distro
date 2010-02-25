/*
 * jQuery textbox list plugin 1.0
 *
 * Copyright (c) 2009-2010 Michael Daum http://michaeldaumconsulting.com
 *
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *
 * Revision: $Id$
 */

/***************************************************************************
 * plugin definition 
 */
;(function($) {

  // extending jquery 
  $.fn.extend({
    textboxlist: function(options) {
       
      // build main options before element iteration
      var opts = $.extend({}, $.TextboxLister.defaults, options);
     
      // create textbox lister for each jquery hit
      return this.each(function() {
        new $.TextboxLister(this, opts);
      });
    }
  });

  // TextboxLister class **************************************************
  $.TextboxLister = function(elem, opts) {
    var self = this;
    self.input = $(elem);

    // build element specific options. 
    // note you may want to install the Metadata plugin
    self.opts = $.extend({}, self.input.metadata(), opts);

    if(!self.opts.inputName) {
      self.opts.inputName = self.input.attr('name');
    }

    // wrap
    self.container = self.input.wrap("<div class="+self.opts.containerClass+"></div>")
      .parent().append("<span class='foswikiClear'></span>");

    // clear button
    if (self.opts.clearControl) {
      $(self.opts.clearControl).click(function() {
        self.clear();
        this.blur();
        return false;
      });
    }

    // reset button
    if (self.opts.resetControl) {
      $(self.opts.resetControl).click(function() {
        self.reset();
        this.blur();
        return false;
      });
    }
   
    // autocompletion
    if (self.opts.autocomplete) {
      var autocompleteOpts = 
        $.extend({},{
            selectFirst:false,
            autoFill:false,
            matchCase:false,
            matchContains:false,
            matchSubset:true
          }, self.opts.autocompleteOpts);
      self.input.attr('autocomplete', 'off').autocomplete(self.opts.autocomplete, autocompleteOpts).
      result(function(event, data, value) {
        //$.log("TEXTBOXLIST: result data="+data+" formatted="+formatted);
        self.select(value);
      });
    } else {
      $.log("TEXTBOXLIST: no autocomplete");
    }

    // autocomplete does not fire the result event on new items
    self.input.bind(($.browser.opera ? "keypress" : "keydown") + ".textboxlist", function(event) {
      // track last key pressed
      if(event.keyCode == 13) {
        var val = self.input.val();
        if (val) {
          self.select([val]);
          event.preventDefault();
          return false;
        }
      }
    });

    // init
    self.currentValues = [];
    if (self.input.val()) {
      self.select(self.input.val().split(/\s*,\s*/).sort(), true);
    }
    self.initialValues = self.currentValues.slice();
    self.input.removeClass('foswikiHidden').show();
  }
 
  // clear selection *****************************************************
  $.TextboxLister.prototype.clear = function() {
    $.log("TEXTBOXLIST: called clear");
    var self = this;
    self.container.find("."+self.opts.listValueClass).remove();
    self.currentValues = [];

    // onClear callback
    if (typeof(self.opts.onClear) == 'function') {
      $.log("TEXTBOXLIST: calling onClear handler");
      self.opts.onClear(self);
    }
  };

  // reset selection *****************************************************
  $.TextboxLister.prototype.reset = function() {
    $.log("TEXTBOXLIST: called reset");
    var self = this;
    self.clear();
    self.select(self.initialValues);

    // onReset callback
    if (typeof(self.opts.onReset) == 'function') {
      $.log("TEXTBOXLIST: calling onReseet handler");
      self.opts.onReset(self);
    }
  };

  // add values to the selection ******************************************
  $.TextboxLister.prototype.select = function(values, suppressCallback) {
    $.log("TEXTBOXLIST: called select("+values+") "+typeof(values));
    var self = this;

    if (typeof(values) === 'object') {
      values = values.join(',');
    } 
    if (typeof(values) !== 'undefined' && typeof(values) !== 'null') {
      values = values.split(/\s*,\s*/).sort();
    } else {
      values = '';
    }

    // only set values not already there
    if (self.currentValues.length > 0) {
      for (var i = 0; i < values.length; i++) {
        var val = values[i];
        var found = false;
        if (!val) {
          continue;
        }
        $.log("val='"+val+"'");
        for (j = 0; j < self.currentValues.length; j++) {
          var currentVal = self.currentValues[j];
          if (currentVal == val) {
            found = true;
            break;
          }
        }
        if (!found) {
          self.currentValues.push(val);
        }
      }
    } else {
      self.currentValues = new Array();
      for (var i = 0; i < values.length; i++) {
        var val = values[i];
        if (val) {
          self.currentValues.push(val);
        }
      }
    }

    if (self.opts.doSort) {
      self.currentValues = self.currentValues.sort();
    }

    $.log("TEXTBOXLIST: self.currentValues="+self.currentValues+"("+self.currentValues.length+")");

    self.container.find("."+self.opts.listValueClass).remove();
    for (var i = self.currentValues.length-1; i >= 0; i--) {
      var val = self.currentValues[i];
      if (!val) 
        continue;
      var input = "<input type='hidden' name='"+self.opts.inputName+"' value='"+val+"' />";
      var close = $("<a href='#' title='remove "+val+"'></a>").
        addClass(self.opts.closeClass).
        click(function() {
          self.deselect.call(self, $(this).parent().find("input").val());
          return false;
        });
      $("<span></span>").addClass(self.opts.listValueClass).
        append(input).
        append(close).
        append(val).
        prependTo(self.container);
    }
    self.input.val('');

    // onSelect callback
    if (!suppressCallback && typeof(self.opts.onSelect) == 'function') {
      $.log("TEXTBOXLIST: calling onSelect handler");
      self.opts.onSelect(self);
    }
  };

  // remove values from the selection *************************************
  $.TextboxLister.prototype.deselect = function(values) {
    $.log("TEXTBOXLIST: called deselect("+values+")");

    var self = this;
    var newValues = new Array();

    if (typeof(values) == 'object') {
      values = values.join(',');
    }
    values = values.split(/\s*,\s*/);
    if (!values.length) {
      return;
    }

    for (var i = 0; i < self.currentValues.length; i++) {
      var currentVal = self.currentValues[i];
      if (!currentVal) 
        continue;
      var found = false;
      for (j = 0; j < values.length; j++) {
        var val = values[j];
        if (val && currentVal == val) {
          found = true;
          break;
        }
      }
      if (!found && currentVal) {
        newValues.push(currentVal);
      }
    }
    self.currentValues = newValues;

    // onDeselect callback
    if (typeof(self.opts.onDeselect) == 'function') {
      $.log("TEXTBOXLIST: calling onDeselect handler");
      self.opts.onDeselect(self);
    }

    self.select(newValues);
  };

  // default settings ****************************************************
  $.TextboxLister.defaults = {
    containerClass: 'jqTextboxListContainer',
    listValueClass: 'jqTextboxListValue',
    closeClass: 'jqTextboxListClose',
    doSort: false,
    inputName: undefined,
    resetControl: undefined,
    clearControl: undefined,
    autocomplete: undefined,
    onClear: undefined,
    onReset: undefined,
    onSelect: undefined,
    onDeselect: undefined
  };
 
})(jQuery);

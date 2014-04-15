
orders = {

  item: {

    edit: function () {
    },

    edit_quantity: function (item) {
      item = jQuery(item);
      toggle_edit.edit(item);

      var quantity_consumer_ordered = item.find('.quantity input');
      quantity_consumer_ordered.focus();
    },

    quantity_keyup: function(context, event) {
      if (event.keyCode == 13) {
        var item = jQuery(context).parents('.item');
        item.find('.more .action-button').get(0).onclick();

        event.preventDefault();
        return false;
      }
    },

    submit: function(context, url) {
      var container = jQuery(context).parents('.order-items-container');
      var item = jQuery(context).parents('.item');
      var quantity_consumer_ordered = item.find('.quantity input');

      loading_overlay.show(container);
      jQuery.post(url, {'item[quantity_consumer_ordered]': quantity_consumer_ordered.val()}, function(){}, 'script');
    },
  },

  admin: {

    toggle_edit: function () {
      toggle_edit.editing().find('.box-edit').toggle(toggle_edit.isEditing());
      sortable_table.edit_arrow_toggle(toggle_edit.editing(), toggle_edit.isEditing());
    },

    select: {
      all: function() {
        jQuery('.order #order_ids_').attr('checked', true)
      },
      none: function() {
        jQuery('.order #order_ids_').attr('checked', false)
      },

      selection: function() {
        var selection = jQuery('.order #order_ids_:checked').parents('.order')
      },

    },
  },

  set_orders_container_max_height: function()
  {
    ordersH = jQuery(window).height();
    ordersH -= 100
    ordersH -= jQuery('#order-column #delivery-box').outerHeight()
    ordersH -= jQuery('#order-column .order-message-title').outerHeight()
    ordersH -= jQuery('#order-status-message').outerHeight()
    ordersH -= jQuery('#order-column .order-message-text').outerHeight()
    ordersH -= jQuery('#order-column .order-message-actions').outerHeight()
    ordersH -= jQuery('#order-column .order-total').last().outerHeight()
    jQuery('.order-items-container .order-items-scroll').css('max-height', ordersH);
  }

};


jQuery(document).ready(function() {
  orders.set_orders_container_max_height();
});

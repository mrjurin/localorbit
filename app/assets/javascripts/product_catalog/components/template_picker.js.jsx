(function() {
  window.lo = window.lo || {};

  var TemplatePicker = React.createClass({
    propTypes: {
      baseUrl: React.PropTypes.string.isRequired,
      cartUrl: React.PropTypes.string.isRequired
    },

    getInitialState: function() {
      return {
        templates: []
      };
    },

    componentWillMount: function() {
      this.getTemplates();
    },

    getTemplates: function() {
      var self = this;
      $.getJSON(self.props.baseUrl + 'order_templates', function(res) {
        self.setState({templates: res.templates});
      });
    },

    addProduct: function(productId, quantity, netPrice, salePrice, fee, lotId, ctId) {
      var deferred = Q.defer();
      $.ajax({
        url: this.props.cartUrl,
        type: 'PUT',
        data: {
          product_id: productId,
          quantity: quantity,
          net_price: netPrice,
          sale_price: salePrice,
          fee: fee,
          lot_id: lotId,
          ct_id: ctId
        },
        success: deferred.resolve,
        error: deferred.reject
      });
      return deferred.promise;
    },

    applyTemplate: function(template) {
      var self = this;
      var promises = _.map(template.items, function(item) {
        return self.addProduct(item.product_id, item.quantity, item.net_price, item.sale_price, item.fee, item.lot_id, item.ct_id);
      });
      Q.allSettled(promises)
        .done(function(res) {
          window.location = '/cart';
        });
    },

    close: function() {
      $('.is-open').removeClass('is-open is-dark is-dim is-modal is-editable mobile-dim');
      $('.popup').addClass('is-hidden');
    },

    render: function() {
      var self = this;
      var templates = _.map(self.state.templates, function(template) {
        return (
          <tr key={template.id}>
            <td>{template.name}</td>
            <td>
              <button className="btn btn--primary app-apply-template-btn" onClick={self.applyTemplate.bind(this, template)}>Apply</button>
            </td>
          </tr>
        );
      });

      return (
        <div className="popup modal is-hidden" id="templatePicker" style={{top: "400px", height: "500px", overflow: "scroll", background: "white", position: "fixed", padding: "20px", width: "50%", borderRadius: "5px"}}>
          <button className="btn pull-right" onClick={this.close}>Close</button>
          <h1><i className="font-icon" data-icon=""></i>&nbsp; Order Templates</h1>
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {templates}
            </tbody>
          </table>
        </div>
      );
    }
  });

  window.lo.TemplatePicker = TemplatePicker;
}).call(this);

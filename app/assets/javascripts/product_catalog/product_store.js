//= require reflux.min
//= require jquery

(function() {
  var ProductActions = Reflux.createActions([
    "setBaseUrl",
    "loadProducts",
    "loadMoreProducts",
    "newQuery",
    "newFilters"
  ]);

  var ProductStore = Reflux.createStore({
    init: function() {
      this.catalog = {
        products: [],
        hasMore: true
      };
      this.url = window.location.protocol + "//" + window.location.host + "/api/v1/products";
      this.parameters = {
        offset: 0,
        category_ids: [],
        seller_ids: []
      };
      this.loading = false;
      this.listenTo(ProductActions.loadProducts, this.loadProducts);
      this.listenTo(ProductActions.loadMoreProducts, this.loadMoreProducts);
      this.listenTo(ProductActions.newQuery, this.newQuery);
      this.listenTo(ProductActions.newFilters, this.newFilters);
    },

    newFilters: function(category_ids, seller_ids) {
      this.parameters.category_ids = category_ids;
      this.parameters.seller_ids = seller_ids;
      this.loadProducts();
    },

    newQuery: function(query) {
      this.parameters.query = query;
      ProductActions.loadProducts();
    },

    loadProducts: function() {
      this.loading = true;
      this.parameters.offset = 0;
      $.getJSON(this.url, this.parameters, this.onLoad, this.onLoadError);
    },

    onLoad: function(res) {
      this.catalog.products = res.products;
      this.catalog.hasMore = (this.catalog.products.length < res.product_total);
      this.trigger(this.catalog);
      this.loading = false;
    },

    loadMoreProducts: function() {
      if(this.loading || !this.catalog.hasMore) return;
      this.loading = true;
      this.parameters.offset = this.catalog.products.length;
      $.getJSON(this.url, this.parameters, this.onLoadMore, this.onLoadError);
    },

    onLoadMore: function(res) {
      this.catalog.products = this.catalog.products.concat(res.products);
      this.catalog.hasMore = (this.catalog.products.length < res.product_total);
      this.trigger(this.catalog);
      this.loading = false;
    },

    onLoadError: function(err) {
      console.error('Error loading products', err);
      this.loading = false;
    }
  });

  window.lo = window.lo || {};
  _.extend(window.lo, {
    ProductStore: ProductStore,
    ProductActions: ProductActions
  });
}).call(this);
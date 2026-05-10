<?php
class ControllerCommonHome extends Controller {
    public function index() {
        $this->response->redirect($this->url->link('product/product', 'product_id=1', true));
    }
}

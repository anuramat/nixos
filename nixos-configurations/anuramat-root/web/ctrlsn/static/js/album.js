import PhotoSwipeLightbox from "/static/js/photoswipe-lightbox.esm.min.js";

const lightbox = new PhotoSwipeLightbox({
  gallery: "#album",
  children: "a",
  preloaderDelay: 0,
  zoom: false,
  // by default capped at 100%, so photos that fit the screen can't zoom
  secondaryZoomLevel: ({ fit }) => fit * 2,
  pswpModule: () => import("/static/js/photoswipe.esm.min.js"),
});
// by default only the slide opened from the album gets its preview
lightbox.addFilter("placeholderSrc", (_, content) => content.data.msrc);
lightbox.on("uiRegister", () => {
  lightbox.pswp.ui.registerElement({
    name: "download",
    title: "Download",
    order: 8,
    isButton: true,
    tagName: "a",
    html: {
      isCustomSVG: true,
      inner:
        '<path d="M20.5 14.3 17.1 18V10h-2.2v7.9l-3.4-3.6L10 16l6 6.1 6-6.1ZM23 23H9v2h14Z" id="pswp__icn-download"/>',
      outlineID: "pswp__icn-download",
    },
    onInit: (el, pswp) => {
      el.setAttribute("download", "");
      // the album link, which goes to the full size
      pswp.on("change", () => (el.href = pswp.currSlide.data.element.href));
    },
  });
});
lightbox.init();

(async (input) => {
  document.body.innerHTML = '<div id=\'machete\' style=\'width: 100vw; height: 100vh;\'></div>'
  const viewer = new Hover.Machete.Viewer(document.getElementById('machete'), {
    useSky: false,
    useTerrain: false,
    useShadowMap: false,
    webgl: {
      context: {
        antialias: true,
        alpha: true,
        preserveDrawingBuffer: true,
        premultipliedAlpha: true,
        autoClear: false,
      }
    }
  });

  const parsedInput = input.map((item) => {
    return JSON.parse(item);
  });

  const orderData = parsedInput[0];
  const modelData = parsedInput[1];
  const macheteData = parsedInput[2];

  let model;
  await new Promise((resolve) => {
    const params = {
      autofocus: false,
      autotexture: false,
      geometry: modelData,
      metadata: macheteData,
      onComplete: () => {
        console.log('model loaded completed');
        resolve()
      },
    };

    model = viewer.loadModel(params);
  });

  const order = new Hover.Order(orderData, {
    includeMarkups: false,
  });

  // apply 'red' to all faces present in a building by default
  const defaultColor = '#ff0000';

  // specify mask colors for each label type
  const labelToColorMapping = {
    402: '#a000a0', // fascia
    403: '#ffff00', // soffit 
    404: '#00ff00', // roof
    405: '#00ffff', // sash
    408: '#0000ff', // door package
  };

  const visibleElements = model.elements.filter((element) => {
    return !!element.visible;
  });

  // apply a color to each face according to their label
  visibleElements.forEach((modelElement) => {
    const labelCandidates = Object.keys(labelToColorMapping);
    const selectedLabelId = labelCandidates.find((labelId) => {
      return modelElement.labels.includes(Number(labelId));
    });

    let selectedColor;
    if (selectedLabelId === undefined) {
      selectedColor = defaultColor;
    } else {
      selectedColor = labelToColorMapping[selectedLabelId];
    }

    modelElement.color = selectedColor;
    const entity = modelElement.individualEntity;
    entity.material = new THREE.MeshBasicMaterial({
      color: new THREE.Color().setStyle(selectedColor).getHex(),
    });
  });

  for (let i = 0; i < order.calibratedCameras.length; ++i) {
    const calibratedCamera = order.calibratedCameras[i];

    viewer.setCameraFromCamera(calibratedCamera, model);
    viewer.scene.needsUpdate = true;

    const { width, height } = calibratedCamera.calibratedImage;
    await setSize(width, height);

    const cameraName = ['calibrated_camera', calibratedCamera.id].join('_');
    await captureScreenshot({ name: [order.id, cameraName].join('_') });
  }
});

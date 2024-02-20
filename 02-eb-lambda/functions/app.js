exports.handler = async (event, context) => {
    console.log('EVENT: ', event)
    const { source, detail, 'detail-type': detailType } = event;

    const { album } = detail;

    console.log('Source: ', source);
    console.log('Detail Type: ', detailType)
    return JSON.stringify({
        name: album,
        'release-year': 1978
    });
}
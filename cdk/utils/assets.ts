import path = require('path');

const ASSET_DIR = '../../assets';
const TMPL_DIR = '../../templates';

export function getAssetPath(assetName: string): string {
    return path.resolve(__dirname, ASSET_DIR, assetName);
}

export function getTemplatePath(tmplName: string): string {
    return path.resolve(__dirname, TMPL_DIR, tmplName);
}
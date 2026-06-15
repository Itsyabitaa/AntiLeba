import { useEffect, useState } from 'react';

import { fetchPhotoBlob } from '../api/client';
import type { PhotoRow } from '../api/types';

interface Props {
  photos: PhotoRow[];
  loading: boolean;
}

function PhotoThumb({ photo }: { photo: PhotoRow }) {
  const [src, setSrc] = useState<string | null>(null);
  const [error, setError] = useState(false);

  useEffect(() => {
    let active = true;
    let objectUrl: string | null = null;

    fetchPhotoBlob(photo.id)
      .then((url) => {
        if (!active) {
          URL.revokeObjectURL(url);
          return;
        }
        objectUrl = url;
        setSrc(url);
      })
      .catch(() => active && setError(true));

    return () => {
      active = false;
      if (objectUrl) URL.revokeObjectURL(objectUrl);
    };
  }, [photo.id]);

  return (
    <figure className="photo-card">
      {src ? (
        <img src={src} alt={`Evidence ${photo.trigger}`} loading="lazy" />
      ) : (
        <div className="photo-placeholder">
          {error ? 'Failed to load' : 'Loading…'}
        </div>
      )}
      <figcaption>
        <span className="badge">{photo.trigger}</span>
        <span className="muted">
          {new Date(photo.capturedAt).toLocaleString()}
        </span>
      </figcaption>
    </figure>
  );
}

export function PhotoGallery({ photos, loading }: Props) {
  if (loading) {
    return <p className="muted">Loading evidence photos…</p>;
  }

  if (photos.length === 0) {
    return <p className="muted">No photos uploaded for this device.</p>;
  }

  return (
    <div className="photo-grid">
      {photos.map((photo) => (
        <PhotoThumb key={photo.id} photo={photo} />
      ))}
    </div>
  );
}

import React, { useEffect } from "react";
import * as dashjs from "dashjs";

type DashPlayerProps = {
  src: string;
}
export const DashPlayer: React.FC<DashPlayerProps> = ({ src }) => {
  const videoRef = React.useRef<HTMLVideoElement>(null);

  useEffect(() => {
    const player = dashjs.MediaPlayer().create();
    player.initialize(videoRef.current!, src, true);

    return () => {
      player.reset();
    }
  }, [src])

  return (
    <video ref={videoRef} controls style={{ width: '100%'}} />
  );
}
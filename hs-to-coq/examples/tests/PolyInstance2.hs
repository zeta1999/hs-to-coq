class M a where
  mempty :: a

instance M [a] where
  mempty = []

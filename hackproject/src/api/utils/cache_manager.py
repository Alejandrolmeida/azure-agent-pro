"""
============================================================================
Cache Manager Module
============================================================================
Gestión de cache usando Azure Blob Storage para optimizar:
- Respuestas de APIs externas (BiciMAD, Calidad del Aire)
- Rutas calculadas frecuentemente

Implementa TTL (Time To Live) de 20 minutos para datos en tiempo real
============================================================================
"""

import json
import logging
from typing import Optional, Any, Dict
from datetime import datetime, timedelta
from azure.storage.blob import BlobServiceClient, ContainerClient
from azure.core.exceptions import ResourceNotFoundError

logger = logging.getLogger(__name__)


class CacheManager:
    """Gestor de cache usando Azure Blob Storage"""
    
    # TTL por tipo de dato (en minutos)
    TTL_CONFIG = {
        'bicimad_stations': 20,      # 20 min (datos en tiempo real)
        'air_quality': 20,           # 20 min (datos en tiempo real)
        'routes': 1440,              # 24 horas (rutas cambian poco)
        'default': 20
    }
    
    # Contenedores de blob storage
    CONTAINERS = {
        'bicimad': 'bicimad-cache',
        'air_quality': 'airquality-cache',
        'routes': 'routes-cache'
    }
    
    def __init__(
        self, 
        connection_string: Optional[str] = None,
        storage_account_name: Optional[str] = None,
        use_local_cache: bool = False
    ):
        """
        Args:
            connection_string: Azure Storage connection string
            storage_account_name: Nombre de la cuenta de storage
            use_local_cache: Si es True, usa cache en memoria (para testing)
        """
        self.use_local_cache = use_local_cache
        
        if use_local_cache:
            logger.info("Using local in-memory cache (testing mode)")
            self._local_cache: Dict[str, Dict] = {}
        else:
            if not connection_string:
                raise ValueError("connection_string is required for Azure Blob cache")
            
            self.blob_service_client = BlobServiceClient.from_connection_string(
                connection_string
            )
            self._ensure_containers()
    
    def _ensure_containers(self):
        """Crea contenedores si no existen"""
        for container_name in self.CONTAINERS.values():
            try:
                container_client = self.blob_service_client.get_container_client(
                    container_name
                )
                if not container_client.exists():
                    logger.info(f"Creating container: {container_name}")
                    container_client.create_container()
            except Exception as e:
                logger.error(f"Error ensuring container {container_name}: {e}")
    
    async def get(
        self, 
        key: str, 
        cache_type: str = 'default'
    ) -> Optional[Any]:
        """
        Recupera valor del cache.
        
        Args:
            key: Clave única del cache
            cache_type: Tipo de dato ('bicimad_stations', 'air_quality', 'routes')
            
        Returns:
            Valor cacheado o None si no existe o expiró
        """
        if self.use_local_cache:
            return self._get_local(key)
        
        return await self._get_blob(key, cache_type)
    
    async def set(
        self,
        key: str,
        value: Any,
        cache_type: str = 'default',
        ttl_minutes: Optional[int] = None
    ) -> bool:
        """
        Guarda valor en cache.
        
        Args:
            key: Clave única del cache
            value: Valor a cachear (debe ser JSON-serializable)
            cache_type: Tipo de dato
            ttl_minutes: TTL custom (si no se especifica, usa TTL_CONFIG)
            
        Returns:
            True si se guardó correctamente
        """
        if self.use_local_cache:
            return self._set_local(key, value, cache_type, ttl_minutes)
        
        return await self._set_blob(key, value, cache_type, ttl_minutes)
    
    async def invalidate(self, key: str, cache_type: str = 'default') -> bool:
        """
        Invalida entrada del cache.
        
        Args:
            key: Clave a invalidar
            cache_type: Tipo de dato
            
        Returns:
            True si se invalidó correctamente
        """
        if self.use_local_cache:
            return self._invalidate_local(key)
        
        return await self._invalidate_blob(key, cache_type)
    
    async def clear_all(self, cache_type: Optional[str] = None) -> bool:
        """
        Limpia todo el cache o un tipo específico.
        
        Args:
            cache_type: Si se especifica, solo limpia ese tipo
            
        Returns:
            True si se limpió correctamente
        """
        if self.use_local_cache:
            if cache_type:
                keys_to_delete = [
                    k for k in self._local_cache.keys() 
                    if k.startswith(f"{cache_type}:")
                ]
                for key in keys_to_delete:
                    del self._local_cache[key]
            else:
                self._local_cache.clear()
            return True
        
        # Para Azure Blob, eliminar por contenedor
        try:
            if cache_type:
                container_name = self.CONTAINERS.get(cache_type)
                if container_name:
                    container_client = self.blob_service_client.get_container_client(
                        container_name
                    )
                    blobs = container_client.list_blobs()
                    for blob in blobs:
                        container_client.delete_blob(blob.name)
            else:
                for container_name in self.CONTAINERS.values():
                    container_client = self.blob_service_client.get_container_client(
                        container_name
                    )
                    blobs = container_client.list_blobs()
                    for blob in blobs:
                        container_client.delete_blob(blob.name)
            return True
        except Exception as e:
            logger.error(f"Error clearing cache: {e}")
            return False
    
    # ========================================================================
    # Local Cache Implementation (para testing sin Azure)
    # ========================================================================
    
    def _get_local(self, key: str) -> Optional[Any]:
        """Recupera del cache local en memoria"""
        if key not in self._local_cache:
            return None
        
        cached_data = self._local_cache[key]
        
        # Verificar expiración
        expires_at = datetime.fromisoformat(cached_data['expires_at'])
        if datetime.utcnow() > expires_at:
            del self._local_cache[key]
            logger.debug(f"Cache expired for key: {key}")
            return None
        
        logger.debug(f"Cache hit for key: {key}")
        return cached_data['value']
    
    def _set_local(
        self,
        key: str,
        value: Any,
        cache_type: str,
        ttl_minutes: Optional[int]
    ) -> bool:
        """Guarda en cache local"""
        ttl = ttl_minutes or self.TTL_CONFIG.get(cache_type, self.TTL_CONFIG['default'])
        expires_at = datetime.utcnow() + timedelta(minutes=ttl)
        
        self._local_cache[key] = {
            'value': value,
            'expires_at': expires_at.isoformat(),
            'cached_at': datetime.utcnow().isoformat()
        }
        
        logger.debug(f"Cached locally: {key} (TTL: {ttl} min)")
        return True
    
    def _invalidate_local(self, key: str) -> bool:
        """Invalida entrada del cache local"""
        if key in self._local_cache:
            del self._local_cache[key]
            logger.debug(f"Invalidated cache key: {key}")
            return True
        return False
    
    # ========================================================================
    # Azure Blob Storage Implementation
    # ========================================================================
    
    async def _get_blob(
        self, 
        key: str, 
        cache_type: str
    ) -> Optional[Any]:
        """Recupera del Azure Blob Storage"""
        container_name = self._get_container_name(cache_type)
        blob_name = self._sanitize_key(key)
        
        try:
            container_client = self.blob_service_client.get_container_client(
                container_name
            )
            blob_client = container_client.get_blob_client(blob_name)
            
            # Descargar blob
            blob_data = blob_client.download_blob()
            content = blob_data.readall()
            cached_data = json.loads(content)
            
            # Verificar expiración
            expires_at = datetime.fromisoformat(cached_data['expires_at'])
            if datetime.utcnow() > expires_at:
                await self._invalidate_blob(key, cache_type)
                logger.debug(f"Cache expired for key: {key}")
                return None
            
            logger.debug(f"Cache hit for key: {key}")
            return cached_data['value']
            
        except ResourceNotFoundError:
            logger.debug(f"Cache miss for key: {key}")
            return None
        except Exception as e:
            logger.error(f"Error retrieving from cache: {e}")
            return None
    
    async def _set_blob(
        self,
        key: str,
        value: Any,
        cache_type: str,
        ttl_minutes: Optional[int]
    ) -> bool:
        """Guarda en Azure Blob Storage"""
        container_name = self._get_container_name(cache_type)
        blob_name = self._sanitize_key(key)
        
        ttl = ttl_minutes or self.TTL_CONFIG.get(cache_type, self.TTL_CONFIG['default'])
        expires_at = datetime.utcnow() + timedelta(minutes=ttl)
        
        cached_data = {
            'value': value,
            'expires_at': expires_at.isoformat(),
            'cached_at': datetime.utcnow().isoformat(),
            'cache_type': cache_type,
            'ttl_minutes': ttl
        }
        
        try:
            container_client = self.blob_service_client.get_container_client(
                container_name
            )
            blob_client = container_client.get_blob_client(blob_name)
            
            # Serializar a JSON
            content = json.dumps(cached_data, ensure_ascii=False, indent=2)
            
            # Subir blob
            blob_client.upload_blob(
                content,
                overwrite=True,
                metadata={
                    'cache_type': cache_type,
                    'expires_at': expires_at.isoformat()
                }
            )
            
            logger.debug(f"Cached to blob: {key} (TTL: {ttl} min)")
            return True
            
        except Exception as e:
            logger.error(f"Error writing to cache: {e}")
            return False
    
    async def _invalidate_blob(self, key: str, cache_type: str) -> bool:
        """Invalida entrada del blob storage"""
        container_name = self._get_container_name(cache_type)
        blob_name = self._sanitize_key(key)
        
        try:
            container_client = self.blob_service_client.get_container_client(
                container_name
            )
            blob_client = container_client.get_blob_client(blob_name)
            blob_client.delete_blob()
            
            logger.debug(f"Invalidated blob cache key: {key}")
            return True
            
        except ResourceNotFoundError:
            return False
        except Exception as e:
            logger.error(f"Error invalidating cache: {e}")
            return False
    
    # ========================================================================
    # Helper Methods
    # ========================================================================
    
    def _get_container_name(self, cache_type: str) -> str:
        """Obtiene nombre del contenedor según tipo de cache"""
        return self.CONTAINERS.get(cache_type, self.CONTAINERS['routes'])
    
    def _sanitize_key(self, key: str) -> str:
        """
        Sanitiza clave para uso como blob name.
        Azure Blob names no pueden contener ciertos caracteres.
        """
        # Reemplazar caracteres problemáticos
        sanitized = key.replace('/', '_')
        sanitized = sanitized.replace(':', '_')
        sanitized = sanitized.replace('?', '_')
        sanitized = sanitized.replace('&', '_')
        sanitized = sanitized.replace(' ', '_')
        
        # Azure blob names max 1024 caracteres
        if len(sanitized) > 1024:
            # Usar hash para claves muy largas
            import hashlib
            hash_suffix = hashlib.md5(key.encode()).hexdigest()
            sanitized = sanitized[:1000] + '_' + hash_suffix
        
        return sanitized
    
    def generate_cache_key(
        self,
        prefix: str,
        *args,
        **kwargs
    ) -> str:
        """
        Genera clave de cache consistente.
        
        Args:
            prefix: Prefijo del tipo de dato
            *args: Argumentos posicionales para la clave
            **kwargs: Argumentos nombrados para la clave
            
        Returns:
            Clave de cache string
            
        Example:
            >>> cache.generate_cache_key('route', 40.4168, -3.7038, 40.4558, -3.6883)
            'route_40.4168_-3.7038_40.4558_-3.6883'
            
            >>> cache.generate_cache_key('air_quality', lat=40.4168, lon=-3.7038)
            'air_quality_lat:40.4168_lon:-3.7038'
        """
        parts = [prefix]
        
        # Añadir args
        for arg in args:
            if isinstance(arg, float):
                parts.append(f"{arg:.4f}")
            else:
                parts.append(str(arg))
        
        # Añadir kwargs (ordenados para consistencia)
        for key in sorted(kwargs.keys()):
            value = kwargs[key]
            if isinstance(value, float):
                parts.append(f"{key}:{value:.4f}")
            else:
                parts.append(f"{key}:{value}")
        
        return '_'.join(parts)
    
    def get_cache_stats(self) -> Dict[str, Any]:
        """
        Obtiene estadísticas del cache.
        
        Returns:
            Dict con stats (solo disponible para local cache)
        """
        if not self.use_local_cache:
            return {
                'type': 'azure_blob',
                'stats_available': False,
                'message': 'Stats not available for Azure Blob Storage'
            }
        
        # Calcular stats del cache local
        total_entries = len(self._local_cache)
        expired_entries = 0
        valid_entries = 0
        
        now = datetime.utcnow()
        
        for cached_data in self._local_cache.values():
            expires_at = datetime.fromisoformat(cached_data['expires_at'])
            if now > expires_at:
                expired_entries += 1
            else:
                valid_entries += 1
        
        return {
            'type': 'local_memory',
            'total_entries': total_entries,
            'valid_entries': valid_entries,
            'expired_entries': expired_entries,
            'hit_ratio': 'N/A (not tracked in this implementation)'
        }
